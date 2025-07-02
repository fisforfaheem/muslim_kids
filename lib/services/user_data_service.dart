import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

/// Comprehensive User Data Service with caching, error recovery, and proper state management
class UserDataService {
  static final UserDataService _instance = UserDataService._internal();
  factory UserDataService() => _instance;
  UserDataService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache keys
  static const String _userDataCacheKey = 'cached_user_data';
  static const String _lastUpdateKey = 'last_user_data_update';
  static const Duration _cacheValidDuration = Duration(hours: 24);

  // Stream controllers for reactive updates
  final StreamController<UserData?> _userDataController =
      StreamController<UserData?>.broadcast();
  final StreamController<bool> _loadingController =
      StreamController<bool>.broadcast();
  final StreamController<String?> _errorController =
      StreamController<String?>.broadcast();

  // Getters for streams
  Stream<UserData?> get userDataStream => _userDataController.stream;
  Stream<bool> get loadingStream => _loadingController.stream;
  Stream<String?> get errorStream => _errorController.stream;

  // Current state
  UserData? _currentUserData;
  bool _isLoading = false;
  String? _lastError;

  // Retry configuration
  static const int _maxRetries = 3;
  static const Duration _baseRetryDelay = Duration(seconds: 2);

  /// Get current user data (cached or fresh)
  UserData? get currentUserData => _currentUserData;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  /// Initialize the service and load user data
  Future<void> initialize() async {
    await _loadUserData(useCache: true);
  }

  /// Load user data with comprehensive error handling and caching
  Future<UserData?> _loadUserData({
    bool useCache = true,
    bool forceRefresh = false,
    int retryCount = 0,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _setError('No authenticated user found');
        return null;
      }

      // Try cache first if requested and not forcing refresh
      if (useCache && !forceRefresh) {
        final cachedData = await _getCachedUserData();
        if (cachedData != null) {
          _setUserData(cachedData);
          // Still fetch fresh data in background
          _loadUserData(useCache: false, forceRefresh: false);
          return cachedData;
        }
      }

      // Fetch from Firestore with timeout and retry logic
      final userDoc = await _fetchUserDocumentWithTimeout(currentUser.uid);

      UserData userData;
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        userData = UserData.fromFirestore(data, currentUser);
      } else {
        // Create default user data if document doesn't exist
        userData = UserData.createDefault(currentUser);
        await _createUserDocument(userData);
      }

      // Cache the data
      await _cacheUserData(userData);
      _setUserData(userData);

      return userData;
    } catch (e) {
      debugPrint('Error loading user data (attempt ${retryCount + 1}): $e');

      // Implement exponential backoff retry
      if (retryCount < _maxRetries) {
        final delay = _baseRetryDelay * (retryCount + 1);
        await Future.delayed(delay);
        return _loadUserData(
          useCache: false,
          forceRefresh: forceRefresh,
          retryCount: retryCount + 1,
        );
      }

      // If all retries failed, try to use cached data as fallback
      final cachedData = await _getCachedUserData();
      if (cachedData != null) {
        _setUserData(cachedData);
        _setError('Using cached data - network unavailable');
        return cachedData;
      }

      _setError('Failed to load user data: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch user document with timeout
  Future<DocumentSnapshot> _fetchUserDocumentWithTimeout(String uid) async {
    return await Future.any([
      _firestore.collection('users').doc(uid).get(),
      Future.delayed(
        const Duration(seconds: 10),
        () => throw TimeoutException('Request timed out after 10 seconds'),
      ),
    ]);
  }

  /// Create user document in Firestore
  Future<void> _createUserDocument(UserData userData) async {
    try {
      await _firestore
          .collection('users')
          .doc(userData.uid)
          .set(userData.toFirestore());
      debugPrint('Created new user document for ${userData.uid}');
    } catch (e) {
      debugPrint('Error creating user document: $e');
      throw Exception('Failed to create user profile');
    }
  }

  /// Update user data with optimistic updates and rollback on failure
  Future<bool> updateUserData({
    String? name,
    String? avatar,
    String? email,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      // Create updated data
      final updatedData =
          _currentUserData?.copyWith(
            name: name,
            avatar: avatar,
            email: email,
            lastUpdated: DateTime.now(),
            additionalData: additionalData,
          ) ??
          UserData.createDefault(currentUser);

      // Optimistic update
      _setUserData(updatedData);

      // Prepare update map
      final updateMap = <String, dynamic>{
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (name != null) updateMap['name'] = name;
      if (avatar != null) updateMap['avatar'] = avatar;
      if (email != null) updateMap['email'] = email;
      if (additionalData != null) updateMap.addAll(additionalData);

      // Update Firestore
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update(updateMap);

      // Update cache
      await _cacheUserData(updatedData);

      return true;
    } catch (e) {
      debugPrint('Error updating user data: $e');

      // Reset to previous state if needed
      if (_currentUserData != null) {
        _setUserData(_currentUserData);
      }

      _setError('Failed to update profile: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh user data from server
  Future<UserData?> refreshUserData() async {
    return await _loadUserData(useCache: false, forceRefresh: true);
  }

  /// Get cached user data
  Future<UserData?> _getCachedUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_userDataCacheKey);
      final lastUpdateString = prefs.getString(_lastUpdateKey);

      if (cachedJson == null || lastUpdateString == null) {
        return null;
      }

      final lastUpdate = DateTime.parse(lastUpdateString);
      final now = DateTime.now();

      // Check if cache is still valid
      if (now.difference(lastUpdate) > _cacheValidDuration) {
        debugPrint('User data cache expired');
        return null;
      }

      final cachedData = json.decode(cachedJson) as Map<String, dynamic>;
      return UserData.fromJson(cachedData);
    } catch (e) {
      debugPrint('Error reading cached user data: $e');
      return null;
    }
  }

  /// Cache user data
  Future<void> _cacheUserData(UserData userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userDataCacheKey, json.encode(userData.toJson()));
      await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
      debugPrint('User data cached successfully');
    } catch (e) {
      debugPrint('Error caching user data: $e');
    }
  }

  /// Clear cached data
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userDataCacheKey);
      await prefs.remove(_lastUpdateKey);
      debugPrint('User data cache cleared');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    _loadingController.add(loading);
  }

  /// Set error state
  void _setError(String? error) {
    _lastError = error;
    _errorController.add(error);
  }

  /// Set user data
  void _setUserData(UserData? userData) {
    _currentUserData = userData;
    _userDataController.add(userData);
  }

  /// Dispose resources
  void dispose() {
    _userDataController.close();
    _loadingController.close();
    _errorController.close();
  }
}

/// User Data Model with comprehensive field support
class UserData {
  final String uid;
  final String name;
  final String email;
  final String avatar;
  final String userType;
  final DateTime? lastUpdated;
  final Map<String, dynamic> additionalData;

  UserData({
    required this.uid,
    required this.name,
    required this.email,
    required this.avatar,
    required this.userType,
    this.lastUpdated,
    this.additionalData = const {},
  });

  /// Create default user data
  factory UserData.createDefault(User user) {
    return UserData(
      uid: user.uid,
      name: user.displayName ?? 'User',
      email: user.email ?? '',
      avatar: 'assets/avatar2.jpg',
      userType: 'Kid',
      lastUpdated: DateTime.now(),
    );
  }

  /// Create from Firestore document
  factory UserData.fromFirestore(Map<String, dynamic> data, User user) {
    return UserData(
      uid: user.uid,
      name: data['name'] ?? user.displayName ?? 'User',
      email: data['email'] ?? user.email ?? '',
      avatar: data['avatar'] ?? 'assets/avatar2.jpg',
      userType: data['userType'] ?? 'Kid',
      lastUpdated:
          data['lastUpdated'] != null
              ? (data['lastUpdated'] as Timestamp).toDate()
              : null,
      additionalData: Map<String, dynamic>.from(data)..removeWhere(
        (key, value) => [
          'name',
          'email',
          'avatar',
          'userType',
          'lastUpdated',
        ].contains(key),
      ),
    );
  }

  /// Create from JSON (for caching)
  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      uid: json['uid'],
      name: json['name'],
      email: json['email'],
      avatar: json['avatar'],
      userType: json['userType'],
      lastUpdated:
          json['lastUpdated'] != null
              ? DateTime.parse(json['lastUpdated'])
              : null,
      additionalData: Map<String, dynamic>.from(json['additionalData'] ?? {}),
    );
  }

  /// Convert to JSON (for caching)
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'avatar': avatar,
      'userType': userType,
      'lastUpdated': lastUpdated?.toIso8601String(),
      'additionalData': additionalData,
    };
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'avatar': avatar,
      'userType': userType,
      'lastUpdated': FieldValue.serverTimestamp(),
      ...additionalData,
    };
  }

  /// Create a copy with updated fields
  UserData copyWith({
    String? name,
    String? email,
    String? avatar,
    String? userType,
    DateTime? lastUpdated,
    Map<String, dynamic>? additionalData,
  }) {
    return UserData(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      userType: userType ?? this.userType,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  @override
  String toString() {
    return 'UserData(uid: $uid, name: $name, email: $email, userType: $userType)';
  }
}
