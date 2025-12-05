import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dio/dio.dart';
import 'features/posts/data/datasources/post_remote_datasource.dart';
import 'features/posts/data/datasources/post_local_datasource.dart';
import 'features/posts/data/repositories/post_repository_impl.dart';
import 'features/posts/domain/usecases/get_posts.dart';
import 'features/posts/domain/usecases/get_post_detail.dart';
import 'features/posts/presentation/bloc/posts_bloc.dart';
import 'features/posts/presentation/pages/posts_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  final localDataSource = PostLocalDataSource();
  await localDataSource.init();
  // await localDataSource.markAllAsUnread(); // when start make all posts unread

  final dio = Dio();
  final remoteDataSource = PostRemoteDataSource(dio: dio);

  final repository = PostRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
  );

  final getPosts = GetPosts(repository);
  final getPostDetail = GetPostDetail(repository);

  final postsBloc = PostsBloc(getPosts: getPosts, repository: repository);

  runApp(MyApp(postsBloc: postsBloc, getPostDetail: getPostDetail));
}

class MyApp extends StatelessWidget {
  final PostsBloc postsBloc;
  final GetPostDetail getPostDetail;

  const MyApp({
    super.key,
    required this.postsBloc,
    required this.getPostDetail,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Knovator Assignment',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: BlocProvider.value(
        value: postsBloc,
        child: PostsPage(getPostDetail: getPostDetail),
      ),
    );
  }
}
