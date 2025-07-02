import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
    // New videos added from user's request
    IslamicVideo.fromYoutubeUrl(
      id: '5',
      title: 'Prophet Yusuf\'s Story - Part 1',
      description:
          'The beautiful story of Prophet Yusuf (Joseph) in Islam for children',
      youtubeUrl: 'https://youtu.be/NC1eXike1jY',
      category: 'Prophet Stories',
    ),
    IslamicVideo.fromYoutubeUrl(
      id: '6',
      title: 'Islamic Animated Movies for Kids',
      description:
          'Educational Islamic cartoon movie for children to learn about faith',
      youtubeUrl: 'https://youtu.be/Ka3YJJybUVo',
      category: 'Moral Stories',
    ),
    IslamicVideo.fromYoutubeUrl(
      id: '7',
      title: 'Prophet Muhammad\'s Life Story',
      description:
          'Learning about the life of Prophet Muhammad (PBUH) through animation',
      youtubeUrl: 'https://youtu.be/YxaQS9rZNZg',
      category: 'Prophet Stories',
    ),
    IslamicVideo.fromYoutubeUrl(
      id: '8',
      title: 'Islamic Moral Values for Children',
      description:
          'Teaching key Islamic moral values to children in an engaging way',
      youtubeUrl: 'https://youtu.be/7iuQI1Izh5o',
      category: 'Values',
    ),
    IslamicVideo.fromYoutubeUrl(
      id: '9',
      title: 'Islamic Etiquette for Kids',
      description:
          'Learn about proper Islamic manners and etiquette for daily life',
      youtubeUrl: 'https://youtu.be/97EnwQ9rFN4',
      category: 'Manners',
    ),
    IslamicVideo.fromYoutubeUrl(
      id: '10',
      title: 'Quran Stories for Children',
      description:
          'Beautiful animated stories from the Holy Quran for young Muslims',
      youtubeUrl: 'https://youtu.be/u2e2Uk4qEXs',
      category: 'Moral Stories',
    ),
    IslamicVideo.fromYoutubeUrl(
      id: '11',
      title: 'Prayer Teaching for Kids',
      description:
          'Teaching children how to pray properly in Islam with animation',
      youtubeUrl: 'https://youtu.be/d5KZoyua3O8',
      category: 'Values',
    ),
  ];

  // Get videos from Firestore or return sample videos if none exist
  Future<List<IslamicVideo>> getIslamicVideos({
    bool forceRefresh = false,
  }) async {
    try {
      // If force refresh is true, clear Firestore and reload all videos
      if (forceRefresh) {
        await _clearAndReuploadAllVideos();
      }

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
      debugPrint('Error getting videos: $e');
      // Return sample videos if there's an error
      return _sampleVideos;
    }
  }

  // Clear all videos and reupload them to Firestore
  Future<void> _clearAndReuploadAllVideos() async {
    try {
      // Get all documents in the collection
      QuerySnapshot querySnapshot =
          await _firestore.collection(_collectionName).get();

      // Delete all existing documents
      WriteBatch deleteBatch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        deleteBatch.delete(doc.reference);
      }
      await deleteBatch.commit();
      debugPrint('Cleared all videos from Firestore');

      // Upload all sample videos
      await _uploadSampleVideosToFirestore();
      debugPrint('Reuploaded all videos to Firestore');
    } catch (e) {
      debugPrint('Error clearing and reuploading videos: $e');
    }
  }



  // Upload sample videos to Firestore
  Future<void> _uploadSampleVideosToFirestore() async {
    try {
      WriteBatch batch = _firestore.batch();

      for (var video in _sampleVideos) {
        DocumentReference docRef = _firestore
            .collection(_collectionName)
            .doc(video.id);
        batch.set(docRef, video.toMap());
      }

      await batch.commit();
      debugPrint('Sample videos uploaded to Firestore');
    } catch (e) {
      debugPrint('Error uploading sample videos: $e');
    }
  }
}
