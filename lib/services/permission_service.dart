import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

/// P0-20: 相册保存运行时权限
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Android SDK ≤ 29 时请求 [Permission.storage]；更高版本依赖 MediaStore 无需该权限
  Future<bool> ensureGallerySavePermission() async {
    if (!Platform.isAndroid) return true;

    final storage = await Permission.storage.status;
    // Android 10+ 使用 MediaStore，storage 权限非必须
    if (storage.isGranted || storage.isLimited) return true;

    final result = await Permission.storage.request();
    if (result.isGranted || result.isLimited) return true;

    if (result.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    // Android 10+ 即使 storage 被拒绝，仍允许尝试 MediaStore 保存
    return true;
  }
}
