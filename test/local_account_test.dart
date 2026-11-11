import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travelmate/local_account.dart';
import 'package:travelmate/trip_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Không thể đăng nhập trước khi có đăng ký', () async {
    final store = TripStore();
    await store.load();
    expect(store.currentUser, isNull);
    expect(store.hasRegisteredAccount, isFalse);
    await expectLater(
      store.signInLocal(identifier: 'ban@gmail.com', password: 'test1234'),
      throwsA(isA<LocalAccountException>()),
    );
  });

  test('Đăng ký, đăng xuất và đăng nhập lại bằng Gmail/SĐT', () async {
    final store = TripStore();
    await store.load();
    await store.registerLocal(
      gmail: 'ban@gmail.com',
      phone: '+84912345678',
      password: 'matkhau789',
    );
    expect(store.hasRegisteredAccount, isTrue);
    // Dang ky xong van phai dang nhap thu cong.
    expect(store.currentUser, isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('travelmate_accounts_v5'), isNot(contains('matkhau789')));
    expect(prefs.getString('travelmate_session_v5'), isNull);
    final beforeLogin = TripStore();
    await beforeLogin.load();
    expect(beforeLogin.hasRegisteredAccount, isTrue);
    expect(beforeLogin.currentUser, isNull);

    await expectLater(
      store.signInLocal(identifier: 'ban@gmail.com', password: 'wrong123'),
      throwsA(isA<LocalAccountException>()),
    );
    await store.signInLocal(identifier: '0912345678', password: 'matkhau789');
    expect(store.currentUser, 'ban@gmail.com');

    final reopened = TripStore();
    await reopened.load();
    expect(reopened.currentUser, 'ban@gmail.com');
  });

  test('Nang cap tu 5.2 buoc dang nhap lai mot lan', () async {
    final original = TripStore();
    await original.load();
    await original.registerLocal(
      gmail: 'cu@gmail.com', phone: '0912345678', password: 'matkhau123',
    );
    await original.signInLocal(identifier: 'cu@gmail.com', password: 'matkhau123');
    final prefs = await SharedPreferences.getInstance();
    // Gia lap phien tu ban cu tu dong dang nhap khi dang ky.
    await prefs.remove('travelmate_manual_signin_v53');
    final migrated = TripStore();
    await migrated.load();
    expect(migrated.hasRegisteredAccount, isTrue);
    expect(migrated.currentUser, isNull);
    expect(prefs.getString('travelmate_session_v5'), isNull);
    await migrated.signInLocal(identifier: 'cu@gmail.com', password: 'matkhau123');
    final reopened = TripStore();
    await reopened.load();
    expect(reopened.currentUser, 'cu@gmail.com');
  });

  test('Chặn đăng ký trùng Gmail hoặc số điện thoại', () async {
    final store = TripStore();
    await store.load();
    await store.registerLocal(
      gmail: 'mot@gmail.com', phone: '0912345678', password: 'matkhau123',
    );
    await expectLater(
      store.registerLocal(
        gmail: 'hai@gmail.com', phone: '0912345678', password: 'khac1234',
      ),
      throwsA(isA<LocalAccountException>()),
    );
  });

  test('Quên mật khẩu chỉ chấp nhận Gmail và SĐT cùng một tài khoản', () async {
    final store = TripStore();
    await store.load();
    await store.registerLocal(
      gmail: 'mot@gmail.com', phone: '0912345678', password: 'matkhau123',
    );
    await store.registerLocal(
      gmail: 'hai@gmail.com', phone: '0987654321', password: 'matkhau456',
    );

    expect(store.verifyRecoveryDetails(
      gmail: 'MOT@GMAIL.COM', phone: '+84912345678',
    ), isTrue);
    expect(
      () => store.verifyRecoveryDetails(
        gmail: 'mot@gmail.com', phone: '0987654321',
      ),
      throwsA(isA<LocalAccountException>().having(
        (e) => e.code, 'code', 'recovery_not_found',
      )),
    );
    await expectLater(
      store.resetPasswordLocal(
        gmail: 'mot@gmail.com', phone: '0987654321',
        newPassword: 'khongduoc123',
      ),
      throwsA(isA<LocalAccountException>()),
    );
    await store.signInLocal(identifier: 'mot@gmail.com', password: 'matkhau123');
    expect(store.currentUser, 'mot@gmail.com');
  });

  test('Đặt lại mật khẩu: lưu mật khẩu mới, giữ dữ liệu, bắt đăng nhập lại', () async {
    final store = TripStore();
    await store.load();
    await store.registerLocal(
      gmail: 'khach@gmail.com', phone: '0912345678', password: 'matkhaucu123',
    );
    await store.registerLocal(
      gmail: 'khac@gmail.com', phone: '0987654321', password: 'taikhoankhac',
    );
    await store.signInLocal(identifier: 'khach@gmail.com', password: 'matkhaucu123');
    expect(store.currentUser, 'khach@gmail.com');

    await store.resetPasswordLocal(
      gmail: 'KHACH@GMAIL.COM',
      phone: '+84912345678',
      newPassword: 'matkhaumoi2026',
    );
    expect(store.currentUser, isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('travelmate_session_v5'), isNull);
    final saved = prefs.getString('travelmate_accounts_v5');
    expect(saved, isNot(contains('matkhaumoi2026')));
    expect(store.registeredAccountCount, 2);

    final reopened = TripStore();
    await reopened.load();
    expect(reopened.currentUser, isNull);
    await expectLater(
      reopened.signInLocal(
        identifier: 'khach@gmail.com', password: 'matkhaucu123',
      ),
      throwsA(isA<LocalAccountException>()),
    );
    await reopened.signInLocal(
      identifier: '0912345678', password: 'matkhaumoi2026',
    );
    expect(reopened.currentUser, 'khach@gmail.com');
    await reopened.signOutLocal();
    await reopened.signInLocal(
      identifier: 'khac@gmail.com', password: 'taikhoankhac',
    );
    expect(reopened.currentUser, 'khac@gmail.com');
  });

  test('Dữ liệu phiên cũ giữ lại nhưng phiên đăng nhập cũ bị yêu cầu đăng ký', () async {
    SharedPreferences.setMockInitialValues({
      'travelmate_local_user': 'nguoidung@gmail.com',
      'trips': '[{"id":"old","name":"Đà Lạt","destination":"Đà Lạt",'
          '"start":"2026-11-01T00:00:00.000",'
          '"end":"2026-11-03T00:00:00.000","activities":[],"packing":[]}]',
    });
    final store = TripStore();
    await store.load();
    expect(store.currentUser, isNull);
    expect(store.trips.length, 1);
    expect(store.trips.single.name, 'Đà Lạt');
  });
}
