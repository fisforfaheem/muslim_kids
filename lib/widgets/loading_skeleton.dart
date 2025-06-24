import 'package:flutter/material.dart';

/// Loading skeleton widget for better user experience
class LoadingSkeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const LoadingSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.baseColor ?? Colors.grey[300]!;
    final highlightColor = widget.highlightColor ?? Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment(-1.0, 0.0),
              end: Alignment(1.0, 0.0),
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                0.0,
                _animation.value,
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Profile loading skeleton
class ProfileLoadingSkeleton extends StatelessWidget {
  const ProfileLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar skeleton
        LoadingSkeleton(
          width: 50,
          height: 50,
          borderRadius: BorderRadius.circular(25),
        ),
        const SizedBox(width: 12),
        // Text skeletons
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LoadingSkeleton(
                width: double.infinity,
                height: 16,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 8),
              LoadingSkeleton(
                width: 120,
                height: 14,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Grid tile loading skeleton
class GridTileLoadingSkeleton extends StatelessWidget {
  const GridTileLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: Colors.grey[200],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingSkeleton(
            width: 50,
            height: 50,
            borderRadius: BorderRadius.circular(25),
          ),
          const SizedBox(height: 10),
          LoadingSkeleton(
            width: 80,
            height: 16,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
    );
  }
}

/// Card loading skeleton
class CardLoadingSkeleton extends StatelessWidget {
  final double? height;
  
  const CardLoadingSkeleton({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LoadingSkeleton(
              width: double.infinity,
              height: height ?? 120,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 12),
            LoadingSkeleton(
              width: double.infinity,
              height: 16,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 8),
            LoadingSkeleton(
              width: 150,
              height: 14,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        ),
      ),
    );
  }
}

/// List tile loading skeleton
class ListTileLoadingSkeleton extends StatelessWidget {
  const ListTileLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: LoadingSkeleton(
        width: 40,
        height: 40,
        borderRadius: BorderRadius.circular(20),
      ),
      title: LoadingSkeleton(
        width: double.infinity,
        height: 16,
        borderRadius: BorderRadius.circular(8),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: LoadingSkeleton(
          width: 120,
          height: 14,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
} 