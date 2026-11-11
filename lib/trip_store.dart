import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_validation.dart';
import 'local_account.dart';
import 'models.dart';

const _accountsKey = 'travelmate_accounts_v5';
const _sessionKey = 'travelmate_session_v5';
const _manualSignInMigrationKey = 'travelmate_manual_signin_v53';

class TripStore extends ChangeNotifier {
  final List<Trip> trips = [];
  final List<LocalAccount> _accounts = [];
  bool english = false;
  bool loaded = false;
  String? currentUser;
  String? error;

  bool get hasRegisteredAccount => _accounts.isNotEmpty;
  int get registeredAccountCount => _accounts.length;
  String tr(String vi, String en) => english ? en : vi;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      english = prefs.getBool('english') ?? false;
      final data = prefs.getString('trips');
      if (data != null) {
        trips
          ..clear()
          ..addAll((jsonDecode(data) as List).map(
            (x) => Trip.fromJson(Map<String, dynamic>.from(x as Map)),
          ));
      }

      final savedAccounts = prefs.getString(_accountsKey);
      _accounts.clear();
      if (savedAccounts != null) {
        _accounts.addAll((jsonDecode(savedAccounts) as List).map(
          (x) => LocalAccount.fromJson(Map<String, dynamic>.from(x as Map)),
        ));
      }

      // Lan dau nang cap tu ban 5.2: xoa session da duoc tao tu dong
      // luc dang ky. Sau khi nguoi dung dang nhap thu cong, session moi
      // duoc giu lai binh thuong giua cac lan mo app.
      if (prefs.getBool(_manualSignInMigrationKey) != true) {
        await prefs.remove(_sessionKey);
        await prefs.setBool(_manualSignInMigrationKey, true);
      }
      // Phien ban 4.x chi kiem tra dinh dang, khong co tai khoan mat khau.
      final savedSession = prefs.getString(_sessionKey);
      currentUser = _accounts.any((a) => a.gmail == savedSession)
          ? savedSession
          : null;
      error = null;
    } catch (e) {
      currentUser = null;
      error = 'Không thể đọc dữ liệu đã lưu: $e';
    } finally {
      loaded = true;
      notifyListeners();
    }
  }

  Future<void> persist() async {
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTrips = await prefs.setString(
        'trips', jsonEncode(trips.map((x) => x.toJson()).toList()),
      );
      final savedLanguage = await prefs.setBool('english', english);
      if (!savedTrips || !savedLanguage) {
        error = 'Không thể lưu dữ liệu trên thiết bị.';
      } else {
        error = null;
      }
    } catch (e) {
      error = 'Không thể lưu dữ liệu: $e';
    }
    notifyListeners();
  }

  String _digest(String password, String salt) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  String _newSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  /// Đăng ký cần đủ Gmail + SĐT + mật khẩu hợp lệ, không gửi OTP.
  /// Đăng ký thành công KHÔNG mở khóa app; phải gọi signInLocal sau đó.
  /// Mật khẩu không lưu thẳng vào SharedPreferences, nhưng đây không phải
  /// cơ chế xác thực an toàn để triển khai thực tế.
  Future<void> registerLocal({
    required String gmail,
    required String phone,
    required String password,
  }) async {
    final email = gmail.trim().toLowerCase();
    final number = normalizePhone(phone);
    if (!isValidGmail(email)) throw const LocalAccountException('invalid_gmail');
    if (!isValidPhone(number)) throw const LocalAccountException('invalid_phone');
    if (!isValidPassword(password)) {
      throw const LocalAccountException('invalid_password');
    }
    if (_accounts.any((a) => a.gmail == email || a.phone == number)) {
      throw const LocalAccountException('already_registered');
    }
    final salt = _newSalt();
    final account = LocalAccount(
      gmail: email,
      phone: number,
      salt: salt,
      passwordDigest: _digest(password, salt),
    );
    final prefs = await SharedPreferences.getInstance();
    final updated = [..._accounts, account];
    final savedAccounts = await prefs.setString(
      _accountsKey,
      jsonEncode(updated.map((a) => a.toJson()).toList()),
    );
    if (!savedAccounts) throw const LocalAccountException('save_failed');
    _accounts.add(account);
    // Dang ky chi tao tai khoan. Phai dang nhap moi duoc vao ung dung.
    // Xoa phien cu (neu co) de khong tu dong vao app sau khi dang ky.
    final cleared = await prefs.remove(_sessionKey);
    if (!cleared) throw const LocalAccountException('save_failed');
    currentUser = null;
    notifyListeners();
  }

  /// Chỉ những tài khoản đã đăng ký trên thiết bị này mới đăng nhập được.
  Future<void> signInLocal({
    required String identifier,
    required String password,
  }) async {
    final input = identifier.trim().toLowerCase();
    final phone = normalizePhone(input);
    LocalAccount? account;
    for (final candidate in _accounts) {
      if (candidate.gmail == input || candidate.phone == phone) {
        account = candidate;
        break;
      }
    }
    if (account == null ||
        !isValidPassword(password) ||
        _digest(password, account.salt) != account.passwordDigest) {
      throw const LocalAccountException('invalid_credentials');
    }
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(_sessionKey, account.gmail);
    if (!saved) throw const LocalAccountException('save_failed');
    currentUser = account.gmail;
    notifyListeners();
  }

  /// Kiểm tra Gmail và số điện thoại PHẢI thuộc cùng một tài khoản đã đăng ký.
  /// Chỉ dùng cho bản demo lưu tài khoản cục bộ: không có OTP hay xác minh
  /// quyền sở hữu Gmail/SĐT, vì vậy không an toàn cho dịch vụ thật.
  LocalAccount _recoveryAccount({
    required String gmail,
    required String phone,
  }) {
    final email = gmail.trim().toLowerCase();
    final number = normalizePhone(phone);
    if (!isValidGmail(email)) {
      throw const LocalAccountException('invalid_gmail');
    }
    if (!isValidPhone(number)) {
      throw const LocalAccountException('invalid_phone');
    }
    for (final account in _accounts) {
      if (account.gmail == email && account.phone == number) return account;
    }
    throw const LocalAccountException('recovery_not_found');
  }

  /// Cho phép sang bước nhập mật khẩu mới khi cả hai thông tin đều trùng khớp.
  bool verifyRecoveryDetails({required String gmail, required String phone}) {
    _recoveryAccount(gmail: gmail, phone: phone);
    return true;
  }

  /// Ghi đè mật khẩu của đúng tài khoản; không xóa tài khoản hoặc lịch trình.
  /// Kiểm tra lại Gmail/SĐT để không thể bỏ qua bước đối chiếu khi gọi hàm.
  Future<void> resetPasswordLocal({
    required String gmail,
    required String phone,
    required String newPassword,
  }) async {
    final account = _recoveryAccount(gmail: gmail, phone: phone);
    if (!isValidPassword(newPassword)) {
      throw const LocalAccountException('invalid_password');
    }

    final salt = _newSalt();
    final updatedAccount = LocalAccount(
      gmail: account.gmail,
      phone: account.phone,
      salt: salt,
      passwordDigest: _digest(newPassword, salt),
    );
    final index = _accounts.indexOf(account);
    final updatedAccounts = [..._accounts];
    updatedAccounts[index] = updatedAccount;

    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(
      _accountsKey,
      jsonEncode(updatedAccounts.map((a) => a.toJson()).toList()),
    );
    if (!saved) throw const LocalAccountException('save_failed');
    _accounts[index] = updatedAccount;

    // Tài khoản vừa đặt lại mật khẩu phải đăng nhập bằng mật khẩu mới.
    if (currentUser == account.gmail) {
      await prefs.remove(_sessionKey);
      currentUser = null;
    }
    notifyListeners();
  }

  Future<void> signOutLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    // Xóa trạng thái truy cập cũ để không còn đường vào ứng dụng bỏ qua đăng ký.
    await prefs.remove('travelmate_local_user');
    await prefs.remove('travelmate_demo_user');
    currentUser = null;
    notifyListeners();
  }

  Future<void> setEnglish(bool value) async {
    english = value;
    await persist();
  }
}
