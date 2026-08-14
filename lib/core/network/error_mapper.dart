import 'api_exception.dart';
import '../../exceptions/missing_credential_exception.dart';

/// P1-3.1：将异常映射为用户可读文案
class ErrorMapper {
  static String toUserMessage(Object error) {
    if (error is MissingCredentialException) return error.message;
    if (error is UnauthorizedException) return error.message;
    if (error is InsufficientBalanceException) return error.message;
    if (error is RateLimitException) return error.message;
    if (error is TimeoutApiException) return error.message;
    if (error is NetworkException) return error.message;
    if (error is ServerException) return error.message;
    if (error is ParseException) return error.message;
    if (error is UnsupportedBackupVersionException) return error.message;
    return '操作失败：$error';
  }
}
