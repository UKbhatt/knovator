import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/post.dart';
import '../../domain/usecases/get_post_detail.dart';
import '../bloc/posts_bloc.dart';
import '../bloc/posts_event.dart';
import '../bloc/posts_state.dart';
import 'post_detail_page.dart';

class PostsPage extends StatefulWidget {
  final GetPostDetail getPostDetail;

  const PostsPage({super.key, required this.getPostDetail});

  @override
  State<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> {
  String _sortBy = 'all';

  void _navigateToDetail(BuildContext context, int postId) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PostDetailPage(postId: postId, getPostDetail: widget.getPostDetail),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.1),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
      ),
    );
  }

  List<Post> _filterAndSortPosts(
    List<Post> posts,
    Map<int, bool> readStatuses,
  ) {
    List<Post> filtered = posts;

    if (_sortBy == 'unread') {
      filtered = filtered
          .where((post) => !(readStatuses[post.id] ?? false))
          .toList();
    } else if (_sortBy == 'read') {
      filtered = filtered
          .where((post) => readStatuses[post.id] ?? false)
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Posts',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isTablet ? 24 : 20,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<PostsBloc, PostsState>(
        builder: (context, state) {
          if (state is PostsInitial) {
            context.read<PostsBloc>().add(const LoadPostsEvent());
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PostsLoading) {
            return _LoadingSkeleton(isTablet: isTablet);
          }

          if (state is PostsError) {
            final screenSize = MediaQuery.of(context).size;
            final isTablet = screenSize.width > 600;

            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? screenSize.width * 0.2 : 24,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: ${state.message}',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: isTablet ? 18 : 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isTablet ? 24 : 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<PostsBloc>().add(const LoadPostsEvent());
                      },
                      child: Text(
                        'Retry',
                        style: TextStyle(fontSize: isTablet ? 16 : 14),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is PostsLoaded || state is PostsSyncing) {
            final posts = state is PostsLoaded
                ? state.posts
                : (state as PostsSyncing).updatedPosts;
            final readStatuses = state is PostsLoaded
                ? state.readStatuses
                : (state as PostsSyncing).readStatuses;
            final isOffline = state is PostsLoaded
                ? state.isOffline
                : (state as PostsSyncing).isOffline;

            final filteredPosts = _filterAndSortPosts(posts, readStatuses);
            final unreadCount = posts
                .where((p) => !(readStatuses[p.id] ?? false))
                .length;
            final readCount = posts
                .where((p) => readStatuses[p.id] ?? false)
                .length;

            return BlocListener<PostsBloc, PostsState>(
              listenWhen: (previous, current) {
                return previous != current &&
                    (current is PostsLoaded && current.isOffline);
              },
              listener: (context, state) {
                if (state is PostsLoaded && state.isOffline) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No internet connection'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: RefreshIndicator(
                onRefresh: () async {
                  context.read<PostsBloc>().add(RefreshPostsEvent());
                  await Future.delayed(const Duration(seconds: 1));
                },
                child: Column(
                  children: [
                    if (isOffline)
                      Container(
                        width: double.infinity,
                        color: Colors.orange.shade100,
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.04,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.wifi_off,
                              size: MediaQuery.of(context).size.width * 0.04,
                              color: Colors.orange.shade900,
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.02,
                            ),
                            Flexible(
                              child: Text(
                                'You\'re offline — showing saved content',
                                style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.03,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _FilterChip(
                                    label: 'All',
                                    isSelected: _sortBy == 'all',
                                    count: posts.length,
                                    onTap: () =>
                                        setState(() => _sortBy = 'all'),
                                  ),
                                  const SizedBox(width: 8),
                                  _FilterChip(
                                    label: 'Unread',
                                    isSelected: _sortBy == 'unread',
                                    count: unreadCount,
                                    onTap: () =>
                                        setState(() => _sortBy = 'unread'),
                                  ),
                                  const SizedBox(width: 8),
                                  _FilterChip(
                                    label: 'Read',
                                    isSelected: _sortBy == 'read',
                                    count: readCount,
                                    onTap: () =>
                                        setState(() => _sortBy = 'read'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: filteredPosts.isEmpty
                          ? _EmptyState(sortBy: _sortBy, isTablet: isTablet)
                          : ListView.builder(
                              itemCount: filteredPosts.length,
                              itemBuilder: (context, index) {
                                final post = filteredPosts[index];
                                final isRead = readStatuses[post.id] ?? false;

                                return TweenAnimationBuilder<double>(
                                  duration: Duration(
                                    milliseconds: 300 + (index * 50),
                                  ),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  curve: Curves.easeOut,
                                  builder: (context, value, child) {
                                    return Opacity(
                                      opacity: value,
                                      child: Transform.translate(
                                        offset: Offset(0, 20 * (1 - value)),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: _SwipeablePostItem(
                                    post: post,
                                    isRead: isRead,
                                    getPostDetail: widget.getPostDetail,
                                    onTap: () {
                                      context.read<PostsBloc>().add(
                                        MarkAsReadEvent(post.id),
                                      );
                                      _navigateToDetail(context, post.id);
                                    },
                                    onSwipe: () {
                                      context.read<PostsBloc>().add(
                                        MarkAsReadEvent(post.id),
                                      );
                                      _navigateToDetail(context, post.id);
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          }

          return const Center(child: Text('Unknown state'));
        },
      ),
    );
  }
}

class _SwipeablePostItem extends StatefulWidget {
  final Post post;
  final bool isRead;
  final GetPostDetail getPostDetail;
  final VoidCallback onTap;
  final VoidCallback onSwipe;

  const _SwipeablePostItem({
    required this.post,
    required this.isRead,
    required this.getPostDetail,
    required this.onTap,
    required this.onSwipe,
  });

  @override
  State<_SwipeablePostItem> createState() => _SwipeablePostItemState();
}

class _SwipeablePostItemState extends State<_SwipeablePostItem> {
  double _dragOffset = 0.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _dragOffset += details.delta.dx;
        });
      },
      onHorizontalDragEnd: (details) {
        final swipeThreshold = 100.0;
        if (_dragOffset.abs() > swipeThreshold) {
          widget.onSwipe();
        }
        setState(() {
          _dragOffset = 0.0;
        });
      },
      onHorizontalDragCancel: () {
        setState(() {
          _dragOffset = 0.0;
        });
      },
      child: Transform.translate(
        offset: Offset(_dragOffset * 0.3, 0),
        child: Opacity(
          opacity: 1.0 - (_dragOffset.abs() / 200).clamp(0.0, 0.3),
          child: _PostItem(
            post: widget.post,
            isRead: widget.isRead,
            onTap: widget.onTap,
          ),
        ),
      ),
    );
  }
}

class _PostItem extends StatelessWidget {
  final Post post;
  final bool isRead;
  final VoidCallback onTap;

  const _PostItem({
    required this.post,
    required this.isRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final cardPadding = isTablet ? 20.0 : 16.0;
    final titleFontSize = isTablet ? 16.0 : 15.0;
    final bodyFontSize = isTablet ? 14.0 : 13.0;
    final cardHeight = isTablet ? 72.0 : 64.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: cardHeight,
          padding: EdgeInsets.symmetric(
            horizontal: cardPadding,
            vertical: cardPadding * 0.5,
          ),
          decoration: BoxDecoration(
            color: isRead ? Colors.white : Colors.yellow.shade50,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: isTablet ? 20 : 18,
                    backgroundColor: Colors.grey.shade300,
                    child: Text(
                      'U${post.userId}',
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  if (!isRead)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            post.title,
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: isRead
                                  ? FontWeight.w400
                                  : FontWeight.w600,
                              color: Colors.black87,
                              letterSpacing: 0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      post.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: bodyFontSize,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  final bool isTablet;

  const _LoadingSkeleton({required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return Container(
          height: isTablet ? 72 : 64,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Container(
                width: isTablet ? 40 : 36,
                height: isTablet ? 40 : 36,
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.6,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final int count;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.3)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String sortBy;
  final bool isTablet;

  const _EmptyState({required this.sortBy, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    String message;
    IconData icon;

    if (sortBy == 'unread') {
      message = 'All posts are read';
      icon = Icons.done_all;
    } else if (sortBy == 'read') {
      message = 'No read posts yet';
      icon = Icons.mark_email_read;
    } else {
      message = 'No posts available';
      icon = Icons.inbox;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: isTablet ? 80 : 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
