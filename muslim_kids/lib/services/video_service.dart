import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:muslim_kids/models/islamic_video.dart';

class VideoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'islamic_videos';

  // Sample videos for initial testing
  final List<IslamicVideo> _sampleVideos = [
    IslamicVideo.fromYoutubeUrl(
      id: '1',
      title: 'Islamic Moral Stories',
      description: 'Collection of animated Islamic moral stories for children',
      youtubeUrl: 'https://www.youtube.com/watch?v=h0zhVfgMptY',
      category: 'Moral Stories',
    ),
    IslamicVideo.fromYoutubeUrl(
      id: '2',
      title: 'Prophet Stories for Kids',
      description: 'Learn about the prophets through animated stories',
      youtubeUrl: 'https://www.youtube.com/watch?v=5ysJkEmvLQU',
      category: 'Prophet Stories',
    ),
    IslamicVideo.fromYoutubeUrl(
      id: '3',
      title: 'Good Manners in Islam',
      description: 'Teaching children about good manners in Islam',
      youtubeUrl: 'https://www.youtube.com/watch?v=p12m8vtQoag',
      category: 'Manners',
    ),
    IslamicVideo.fromYoutubeUrl(
      id: '4',
      title: 'Islamic Values for Children',
      description: 'Learn about important Islamic values through animation',
      youtubeUrl: 'https://www.youtube.com/watch?v=KfDsedlR6F0',
      category: 'Values',
    ),
  ];

  // Get videos from Firestore or return sample videos if none exist
  Future<List<IslamicVideo>> getIslamicVideos() async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore.collection(_collectionName).get();

      if (querySnapshot.docs.isEmpty) {
        // If no videos in Firestore, upload sample videos
        await _uploadSampleVideosToFirestore();
        return _sampleVideos;
      }

      // Map Firestore documents to IslamicVideo objects
      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return IslamicVideo.fromMap(data);
      }).toList();
    } catch (e) {
      print('Error getting videos: $e');
      // Return sample videos if there's an error
      return _sampleVideos;
    }
  }

  // Get videos by category
  Future<List<IslamicVideo>> getVideosByCategory(String category) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('category', isEqualTo: category)
          .get();

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return IslamicVideo.fromMap(data);
      }).toList();
    } catch (e) {
      print('Error getting videos by category: $e');
      // Filter sample videos by category if there's an error
      return _sampleVideos
          .where((video) => video.category == category)
          .toList();
    }
  }

  // Upload sample videos to Firestore
  Future<void> _uploadSampleVideosToFirestore() async {
    try {
      WriteBatch batch = _firestore.batch();

      for (var video in _sampleVideos) {
        DocumentReference docRef =
            _firestore.collection(_collectionName).doc(video.id);
        batch.set(docRef, video.toMap());
      }

      await batch.commit();
      print('Sample videos uploaded to Firestore');
    } catch (e) {
      print('Error uploading sample videos: $e');
    }
  }
}
