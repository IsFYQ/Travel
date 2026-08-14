/// P1-3.1：统一 API 异常体系
sealed class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  const NetworkException([super.message = '网络连接失败，请检查网络后重试']);
}

class TimeoutApiException extends ApiException {
  const TimeoutApiException([super.message = '请求超时，请稍后重试']);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'API 密钥无效或已过期']);
}

class RateLimitException extends ApiException {
  const RateLimitException([super.message = '请求过于频繁，请稍后再试']);
}

class InsufficientBalanceException extends ApiException {
  const InsufficientBalanceException([super.message = '账户余额不足']);
}

class ServerException extends ApiException {
  final int statusCode;
  const ServerException(this.statusCode, [super.message = '服务器错误']);
}

class ParseException extends ApiException {
  const ParseException([super.message = '响应解析失败']);
}

/// P1-2.2：备份版本不兼容
class UnsupportedBackupVersionException extends ApiException {
  final int version;
  UnsupportedBackupVersionException(this.version)
      : super('备份文件版本 ($version) 与当前应用不兼容');
}
