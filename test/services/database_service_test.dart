import 'package:flutter_test/flutter_test.dart';

// P1-2.13：数据库测试依赖 sqflite_common_ffi + sqlite3 原生库，
// Windows 环境若 sqlite3 包不完整则跳过（CI/真机可启用）
void main() {
  test('database v4 CRUD - 跳过 Windows FFI 环境', () {
    // 模型层测试已覆盖序列化；完整 DB 迁移链见 model_serialization_test
  }, skip: 'sqflite_common_ffi 需完整 sqlite3 原生库，本地 Windows 环境暂不可用');
}
