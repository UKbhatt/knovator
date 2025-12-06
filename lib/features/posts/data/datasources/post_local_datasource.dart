import 'package:hive_flutter/hive_flutter.dart';
import '../models/post_model.dart';

class PostLocalDataSource {
  static const String postsBoxName = 'posts';
  static const String readStatusBoxName = 'read_status';

  Future<void> init() async {
    try {
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(PostModelAdapter());
      }
      await Hive.openBox<PostModel>(postsBoxName);
      await Hive.openBox<bool>(readStatusBoxName);
    } catch (e) {
      throw Exception('Failed to initialize Hive: $e');
    }
  }

  Future<void> cachePosts(List<PostModel> posts) async {
    final box = Hive.box<PostModel>(postsBoxName);
    await box.clear();
    for (var post in posts) {
      await box.put(post.id, post);
    }
  }

  List<PostModel> getCachedPosts() {
    final box = Hive.box<PostModel>(postsBoxName);
    return box.values.toList();
  }

  Future<void> markAsRead(int id) async {
    final box = Hive.box<bool>(readStatusBoxName);
    await box.put(id, true);
  }

  Map<int, bool> getReadStatus() {
    final box = Hive.box<bool>(readStatusBoxName);
    final Map<int, bool> statusMap = {};
    for (var key in box.keys) {
      statusMap[key as int] = box.get(key) ?? false;
    }
    return statusMap;
  }

  bool isRead(int id) {
    final box = Hive.box<bool>(readStatusBoxName);
    return box.get(id, defaultValue: false) ?? false;
  }

  Future<void> markAllAsUnread() async {
    final box = Hive.box<bool>(readStatusBoxName);
    await box.clear();
  }
}
