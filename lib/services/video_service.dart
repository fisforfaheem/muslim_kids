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
    // Additional videos from Naima Naeem's collection
    IslamicVideo.fromYoutubeUrl(
      id: '12',
      title: 'Islamic Learning for Children - Part 1',
      description: 'Educational Islamic content for young learners',
      youtubeUrl: 'https://youtu.be/kwkcQ7-2XQQ',
      category: 'Educational',
    ),
    IslamicVideo.fromYoutubeUrl(
      id: '13',
      title: 'Islamic Learning for Children - Part 2',
      description: 'More educational Islamic content for children',
      youtubeUrl: 'https://youtu.be/8xdsacBF7Qw',
      category: 'Educational',
    ),
    IslamicVideo.fromYoutubeUrl(
      id: '14',
      title: 'Islamic Learning for Children - Part 3',
      description: 'Continuing Islamic education for young minds',
      youtubeUrl: 'https://youtu.be/769dg9g13ZQ',
      category: 'Educational',
    ),
    IslamicVideo.fromYoutubeUrl(
      id: '15',
      title: 'Islamic Learning for Children - Part 4',
      description: 'Advanced Islamic learning concepts for children',
      youtubeUrl: 'https://youtu.be/9ZYgls1EyC0',
      category: 'Educational',
    ),
    IslamicVideo.fromYoutubeUrl(
      id: '16',
      title: 'Islamic Learning for Children - Part 5',
      description: 'Comprehensive Islamic education for kids',
      youtubeUrl: 'https://youtu.be/SaYybl3Qv3M',
      category: 'Educational',
    ),
    IslamicVideo.fromYoutubeUrl(
      id: '17',
      title: 'Islamic Learning for Children - Part 6',
      description: 'Interactive Islamic learning for young students',
      youtubeUrl: 'https://youtu.be/8_60iWXl7dw',
      category: 'Educational',
    ),
    IslamicVideo.fromYoutubeUrl(
      id: '18',
      title: 'Islamic Learning for Children - Part 7',
      description: 'Engaging Islamic content for children\'s education',
      youtubeUrl: 'https://youtu.be/ECguqMcnlSs',
      category: 'Educational',
    ),
    IslamicVideo.fromYoutubeUrl(
      id: '19',
      title: 'Islamic Learning for Children - Part 8',
      description: 'Progressive Islamic learning for young learners',
      youtubeUrl: 'https://youtu.be/UZ6K5SmmC90',
      category: 'Educational',
    ),
    IslamicVideo.fromYoutubeUrl(
      id: '20',
      title: 'Islamic Learning for Children - Part 9',
      description: 'Advanced Islamic concepts for children',
      youtubeUrl: 'https://youtu.be/ya1tOd2Gmyk',
      category: 'Educational',
    ),
    IslamicVideo.fromYoutubeUrl(
      id: '21',
      title: 'Islamic Learning for Children - Part 10',
      description: 'Comprehensive Islamic education series for kids',
      youtubeUrl: 'https://youtu.be/vTEyUBXarvE',
      category: 'Educational',
    ),
    IslamicVideo.fromYoutubeUrl(
      id: '22',
      title: 'Islamic Learning for Children - Part 11',
      description: 'Interactive Islamic learning experience for children',
      youtubeUrl: 'https://youtu.be/6sGRdHKWYCw',
      category: 'Educational',
    ),
    IslamicVideo.fromYoutubeUrl(
      id: '23',
      title: 'Islamic Learning for Children - Part 12',
      description: 'Educational Islamic content for young minds',
      youtubeUrl: 'https://youtu.be/Fl1H4Hv2_g0',
      category: 'Educational',
    ),
    IslamicVideo.fromYoutubeUrl(
      id: '24',
      title: 'Islamic Learning for Children - Part 13',
      description: 'Progressive Islamic education for children',
      youtubeUrl: 'https://youtu.be/sy8rws8VSwg',
      category: 'Educational',
    ),
    IslamicVideo.fromYoutubeUrl(
      id: '25',
      title: 'Islamic Learning for Children - Part 14',
      description: 'Advanced Islamic learning for young students',
      youtubeUrl: 'https://youtu.be/mWJ-tlZdtK4',
      category: 'Educational',
    ),
    IslamicVideo.fromYoutubeUrl(
      id: '26',
      title: 'Islamic Learning for Children - Part 15',
      description: 'Comprehensive Islamic education for children',
      youtubeUrl: 'https://youtu.be/hCTjjoWXk1Q',
      category: 'Educational',
    ),
    IslamicVideo.fromYoutubeUrl(
      id: '27',
      title: 'Islamic Learning for Children - Part 16',
      description: 'Interactive Islamic learning series for kids',
      youtubeUrl: 'https://youtu.be/NR-Yn7_fx6A',
      category: 'Educational',
    ),
    IslamicVideo.fromYoutubeUrl(
      id: '28',
      title: 'Islamic Learning for Children - Part 17',
      description: 'Educational Islamic content for young learners',
      youtubeUrl: 'https://youtu.be/GZdmj9aoJQ8',
      category: 'Educational',
    ),
    IslamicVideo.fromYoutubeUrl(
      id: '29',
      title: 'Islamic Learning for Children - Part 18',
      description: 'Progressive Islamic education for children',
      youtubeUrl: 'https://youtu.be/ChzxXMwL2RE',
      category: 'Educational',
    ),
    IslamicVideo.fromYoutubeUrl(
      id: '30',
      title: 'Islamic Learning for Children - Part 19',
      description: 'Advanced Islamic learning concepts for kids',
      youtubeUrl: 'https://youtu.be/x29kGcUSpQE',
      category: 'Educational',
    ),
    IslamicVideo.fromYoutubeUrl(
      id: '31',
      title: 'Islamic Learning for Children - Part 20',
      description: 'Final part of comprehensive Islamic education series',
      youtubeUrl: 'https://youtu.be/VOI6TZxEuIw',
      category: 'Educational',
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
