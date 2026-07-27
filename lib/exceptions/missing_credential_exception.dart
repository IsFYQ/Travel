/// P0-5: 未配置 API 凭证时抛出，由 UI 层捕获并引导用户配置
class MissingCredentialException implements Exception {
  final String service;
  final String message;

  MissingCredentialException(this.service, [this.message = '']);

  @override
  String toString() =>
      message.isNotEmpty ? message : '$service 凭证未配置，请先在设置页完成配置';
}
