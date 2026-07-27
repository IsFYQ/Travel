import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// P0-1: 日记图片持久化存储服务
class MediaService {
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();

  static const _uuid = Uuid();

  /// 将图片复制到应用私有目录，返回相对路径 `media/yyyy/MM/uuid.ext`
  Future<String> persistImage(XFile file) async {
    final now = DateTime.now();
    final ext = p.extension(file.path).isNotEmpty
        ? p.extension(file.path)
        : '.jpg';
    final relativePath =
        'media/${now.year}/${now.month.toString().padLeft(2, '0')}/${_uuid.v4()}$ext';
    final destFile = File(await resolveMediaPath(relativePath));
    await destFile.parent.create(recursive: true);
    await File(file.path).copy(destFile.path);
    return relativePath;
  }

  /// 解析存储路径：相对路径拼接 documents 目录，绝对路径原样返回（兼容旧数据）
  Future<String> resolveMediaPath(String stored) async {
    if (stored.startsWith('media/')) {
      final docs = await getApplicationDocumentsDirectory();
      return p.join(docs.path, stored);
    }
    return stored;
  }

  /// 同步版解析（供 build 方法使用，仅拼接路径不访问文件系统）
  String resolveMediaPathSync(String stored, String documentsPath) {
    if (stored.startsWith('media/')) {
      return p.join(documentsPath, stored);
    }
    return stored;
  }

  /// 删除媒体文件（忽略不存在的情况）
  Future<void> deleteMedia(String stored) async {
    if (stored.isEmpty) return;
    try {
      final absolute = await resolveMediaPath(stored);
      final file = File(absolute);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
