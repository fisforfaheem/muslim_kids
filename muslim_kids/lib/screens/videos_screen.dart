import 'package:flutter/material.dart';
import 'package:muslim_kids/models/islamic_video.dart';
import 'package:muslim_kids/screens/video_player_screen.dart';
import 'package:muslim_kids/services/video_service.dart';

class VideosScreen extends StatefulWidget {
  const VideosScreen({super.key});

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen>
    with SingleTickerProviderStateMixin {
  final VideoService _videoService = VideoService();
  late TabController _tabController;
  List<IslamicVideo> _allVideos = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Categories for tab filtering
  final List<String> _categories = [
    'All',
    'Moral Stories',
    'Prophet Stories',
    'Manners',
    'Values',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final videos = await _videoService.getIslamicVideos();

      setState(() {
        _allVideos = videos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load videos: $e';
        _isLoading = false;
      });
    }
  }

  List<IslamicVideo> _getFilteredVideos(String category) {
    if (category == 'All') {
      return _allVideos;
    } else {
      return _allVideos.where((video) => video.category == category).toList();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Islamic Videos'),
        backgroundColor: Colors.green[700],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: _categories.map((category) => Tab(text: category)).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadVideos,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: _categories.map((category) {
                    final filteredVideos = _getFilteredVideos(category);
                    return filteredVideos.isEmpty
                        ? const Center(
                            child: Text('No videos in this category'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: filteredVideos.length,
                            itemBuilder: (context, index) {
                              final video = filteredVideos[index];
                              return VideoCard(
                                video: video,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VideoPlayerScreen(
                                        video: video,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                  }).toList(),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadVideos,
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

class VideoCard extends StatelessWidget {
  final IslamicVideo video;
  final VoidCallback onTap;

  const VideoCard({
    super.key,
    required this.video,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  video.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(
                          Icons.error_outline,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.play_circle_filled,
                        color: Colors.green[700],
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          video.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    video.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      video.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
