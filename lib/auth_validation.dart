/// Định dạng dữ liệu đầu vào dành cho bài tập. Không xác minh số điện thoại
/// hoặc quyền sở hữu email trên máy chủ.
bool isValidGmail(String input) => RegExp(
      r'^[a-zA-Z0-9._%+\-]+@gmail\.com$',
      caseSensitive: false,
    ).hasMatch(input.trim());

String normalizePhone(String input) {
  var value = input.trim().replaceAll(RegExp(r'[\s.\-]'), '');
  if (value.startsWith('+84')) value = '0${value.substring(3)}';
  return value;
}

bool isValidPhone(String input) =>
    RegExp(r'^0[35789][0-9]{8}$').hasMatch(normalizePhone(input));

bool isValidPassword(String input) => input.length >= 6 &&
    input.length <= 64 && !RegExp(r'\s').hasMatch(input);
