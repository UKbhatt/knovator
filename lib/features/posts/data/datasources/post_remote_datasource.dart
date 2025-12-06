import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/post_model.dart';

class PostRemoteDataSource {
  final Dio dio;
  static const String baseUrl = 'https://jsonplaceholder.typicode.com';

  PostRemoteDataSource({required this.dio});

  Future<List<PostModel>> getPosts() async {
    try {
      final response = await dio.get('$baseUrl/posts');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => PostModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NoInternetException();
      } else if (e.type == DioExceptionType.badResponse) {
        throw Exception('Server error: ${e.response?.statusCode}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      if (e is NoInternetException) {
        rethrow;
      }
      throw Exception('Unexpected error: $e');
    }
  }

  Future<PostModel> getPostDetail(int id) async {
    try {
      final response = await dio.get('$baseUrl/posts/$id');
      if (response.statusCode == 200) {
        return PostModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load post detail: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NoInternetException();
      } else if (e.type == DioExceptionType.badResponse) {
        throw Exception('Server error: ${e.response?.statusCode}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      if (e is NoInternetException) {
        rethrow;
      }
      throw Exception('Unexpected error: $e');
    }
  }
}
