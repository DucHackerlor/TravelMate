/// Thông tin đăng ký được lưu cục bộ, không có xác thực qua máy chủ.
class LocalAccount {
  final String gmail;
  final String phone;
  final String salt;
  final String passwordDigest;

  const LocalAccount({
    required this.gmail,
    required this.phone,
    required this.salt,
    required this.passwordDigest,
  });

  Map<String, dynamic> toJson() => {
        'gmail': gmail,
        'phone': phone,
        'salt': salt,
        'passwordDigest': passwordDigest,
      };

  factory LocalAccount.fromJson(Map<String, dynamic> json) => LocalAccount(
        gmail: json['gmail'] as String,
        phone: json['phone'] as String,
        salt: json['salt'] as String,
        passwordDigest: json['passwordDigest'] as String,
      );
}

class LocalAccountException implements Exception {
  final String code;
  const LocalAccountException(this.code);

  @override
  String toString() => 'LocalAccountException($code)';
}
