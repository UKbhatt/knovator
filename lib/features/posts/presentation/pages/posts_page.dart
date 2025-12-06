import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/post.dart';
import '../../domain/usecases/get_post_detail.dart';
import '../bloc/posts_bloc.dart';
import '../bloc/posts_event.dart';
import '../bloc/posts_state.dart';
import 'post_detail_page.dart';

class PostsPage extends StatelessWidget {
  final GetPostDetail getPostDetail;

  const PostsPage({super.key, required this.getPostDetail});

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
            return const Center(child: CircularProgressIndicator());
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
                          SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                          Flexible(
                            child: Text(
                              'You\'re offline — showing saved content',
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width * 0.03,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        final isRead = readStatuses[post.id] ?? false;

                        return TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 300 + (index * 50)),
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
                          child: _PostItem(
                            post: post,
                            isRead: isRead,
                            onTap: () {
                              context.read<PostsBloc>().add(MarkAsReadEvent(post.id));
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) =>
                                      PostDetailPage(
                                    postId: post.id,
                                    getPostDetail: getPostDetail,
                                  ),
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
    final isLandscape = screenSize.width > screenSize.height;
    final horizontalPadding = isTablet 
        ? screenSize.width * 0.1 
        : screenSize.width * 0.04;
    final verticalPadding = isTablet ? 12.0 : 8.0;
    final cardPadding = isTablet ? 24.0 : 16.0;
    final titleFontSize = isTablet ? 22.0 : 18.0;
    final bodyFontSize = isTablet ? 16.0 : 14.0;
    final maxLines = (isLandscape && !isTablet) ? 3 : 2;
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Material(
        elevation: isRead ? 1 : 2,
        borderRadius: BorderRadius.circular(12),
        color: isRead ? Colors.white : Colors.yellow.shade100,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isRead ? Colors.grey.shade200 : Colors.yellow,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Title: ${post.title}',
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                        ),
                      ),
                    ),
                    if (!isRead)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 8 : 5,
                          vertical: isTablet ? 6 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'New',
                          style: TextStyle(
                            fontSize: isTablet ? 12 : 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: isTablet ? 16 : 12),
                Text(
                  post.body,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: bodyFontSize,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
