import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import '../../core/constants/erp_constants.dart';
import '../../core/errors/domain_error.dart';
import '../models/erp_models.dart';

/// Pure-Dart cryptographic SHA-256 and salted key-stretching authentication engine.
/// Never stores or compares passwords in plain text.
class AuthEngine {
  static const int _iterations = 4096;
  static const int _saltBytesLength = 16;

  // Standard FIPS 180-4 SHA-256 round constants
  static const List<int> _k = <int>[
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
    0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
    0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
    0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
    0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
    0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
  ];

  static int _rotr(int x, int n) =>
      ((x & 0xffffffff) >>> n) | ((x << (32 - n)) & 0xffffffff);

  static Uint8List _sha256Bytes(List<int> input) {
    int h0 = 0x6a09e667;
    int h1 = 0xbb67ae85;
    int h2 = 0x3c6ef372;
    int h3 = 0xa54ff53a;
    int h4 = 0x510e527f;
    int h5 = 0x9b05688c;
    int h6 = 0x1f83d9ab;
    int h7 = 0x5be0cd19;

    final int bitLen = input.length * 8;
    final List<int> msg = List<int>.from(input)..add(0x80);
    while ((msg.length % 64) != 56) {
      msg.add(0x00);
    }

    for (int i = 7; i >= 0; i--) {
      msg.add((bitLen >> (i * 8)) & 0xff);
    }

    final Uint32List w = Uint32List(64);
    for (int chunkStart = 0; chunkStart < msg.length; chunkStart += 64) {
      for (int i = 0; i < 16; i++) {
        final int j = chunkStart + (i * 4);
        w[i] = ((msg[j] & 0xff) << 24) |
            ((msg[j + 1] & 0xff) << 16) |
            ((msg[j + 2] & 0xff) << 8) |
            (msg[j + 3] & 0xff);
      }
      for (int i = 16; i < 64; i++) {
        final int s0 = _rotr(w[i - 15], 7) ^
            _rotr(w[i - 15], 18) ^
            ((w[i - 15] & 0xffffffff) >>> 3);
        final int s1 = _rotr(w[i - 2], 17) ^
            _rotr(w[i - 2], 19) ^
            ((w[i - 2] & 0xffffffff) >>> 10);
        w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & 0xffffffff;
      }

      int a = h0;
      int b = h1;
      int c = h2;
      int d = h3;
      int e = h4;
      int f = h5;
      int g = h6;
      int h = h7;

      for (int i = 0; i < 64; i++) {
        final int s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
        final int ch = (e & f) ^ ((~e) & g);
        final int temp1 = (h + s1 + ch + _k[i] + w[i]) & 0xffffffff;
        final int s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
        final int maj = (a & b) ^ (a & c) ^ (b & c);
        final int temp2 = (s0 + maj) & 0xffffffff;

        h = g;
        g = f;
        f = e;
        e = (d + temp1) & 0xffffffff;
        d = c;
        c = b;
        b = a;
        a = (temp1 + temp2) & 0xffffffff;
      }

      h0 = (h0 + a) & 0xffffffff;
      h1 = (h1 + b) & 0xffffffff;
      h2 = (h2 + c) & 0xffffffff;
      h3 = (h3 + d) & 0xffffffff;
      h4 = (h4 + e) & 0xffffffff;
      h5 = (h5 + f) & 0xffffffff;
      h6 = (h6 + g) & 0xffffffff;
      h7 = (h7 + h) & 0xffffffff;
    }

    final ByteData out = ByteData(32);
    final List<int> words = <int>[h0, h1, h2, h3, h4, h5, h6, h7];
    for (int i = 0; i < 8; i++) {
      out.setUint32(i * 4, words[i], Endian.big);
    }
    return out.buffer.asUint8List();
  }

  static String _bytesToHex(List<int> bytes) {
    final StringBuffer sb = StringBuffer();
    for (final int b in bytes) {
      sb.write((b & 0xff).toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }

  static Uint8List _hexToBytes(String hex) {
    final String clean = hex.trim();
    if (clean.length % 2 != 0) {
      throw const FormatException('Invalid hex string');
    }
    final Uint8List result = Uint8List(clean.length ~/ 2);
    for (int i = 0; i < clean.length; i += 2) {
      result[i ~/ 2] = int.parse(clean.substring(i, i + 2), radix: 16);
    }
    return result;
  }

  static String generateRandomHex(int byteCount) {
    Random rng;
    try {
      rng = Random.secure();
    } catch (_) {
      rng = Random();
    }
    final List<int> bytes =
        List<int>.generate(byteCount, (_) => rng.nextInt(256));
    return _bytesToHex(bytes);
  }

  /// Hashes a password with a cryptographic salt and iterative SHA-256 stretching.
  /// Format: `pbkdf2_sha256$<iterations>$<saltHex>$<digestHex>`
  static String hashPassword(String password, {String? customSaltHex}) {
    final String saltHex = customSaltHex ?? generateRandomHex(_saltBytesLength);
    final List<int> saltBytes = _hexToBytes(saltHex);
    final List<int> passwordBytes = utf8.encode(password);

    Uint8List digest = _sha256Bytes(<int>[...saltBytes, ...passwordBytes]);
    for (int i = 1; i < _iterations; i++) {
      final List<int> roundInput = <int>[
        ...digest,
        ...saltBytes,
        ...passwordBytes,
        i & 0xff,
        (i >> 8) & 0xff,
      ];
      digest = _sha256Bytes(roundInput);
    }
    return 'pbkdf2_sha256\$$_iterations\$$saltHex\$${_bytesToHex(digest)}';
  }

  /// Constant-time verification of a password against a stored passwordHash.
  static bool verifyPassword(String password, String storedHash) {
    final List<String> parts = storedHash.split('\$');
    if (parts.length != 4 || parts[0] != 'pbkdf2_sha256') {
      return false;
    }
    final int? iterations = int.tryParse(parts[1]);
    final String saltHex = parts[2];
    final String expectedHex = parts[3];
    if (iterations == null ||
        iterations <= 0 ||
        saltHex.isEmpty ||
        expectedHex.isEmpty) {
      return false;
    }

    try {
      final List<int> saltBytes = _hexToBytes(saltHex);
      final List<int> passwordBytes = utf8.encode(password);
      Uint8List digest = _sha256Bytes(<int>[...saltBytes, ...passwordBytes]);
      for (int i = 1; i < iterations; i++) {
        final List<int> roundInput = <int>[
          ...digest,
          ...saltBytes,
          ...passwordBytes,
          i & 0xff,
          (i >> 8) & 0xff,
        ];
        digest = _sha256Bytes(roundInput);
      }
      final Uint8List expectedBytes = _hexToBytes(expectedHex);
      if (digest.length != expectedBytes.length) return false;
      int diff = 0;
      for (int i = 0; i < digest.length; i++) {
        diff |= digest[i] ^ expectedBytes[i];
      }
      return diff == 0;
    } catch (_) {
      return false;
    }
  }

  /// Creates the initial bootstrap administrator account when the database is empty.
  static UserAccount createDefaultAdminUser({
    String username = 'admin',
    String email = 'admin@efa.local',
    String fullName = 'System Administrator',
    String initialPassword = r'Admin@12345',
    String? nowIso,
  }) {
    final String timestamp = nowIso ?? DateTime.now().toUtc().toIso8601String();
    return UserAccount(
      id: 'USR-ADMIN-001',
      username: username.trim().toLowerCase(),
      email: email.trim().toLowerCase(),
      fullName: fullName.trim(),
      role: UserRole.admin,
      passwordHash: hashPassword(initialPassword),
      isActive: true,
      createdAt: timestamp,
    );
  }

  static PublicUser toPublicUser(UserAccount user) {
    return PublicUser(
      id: user.id,
      username: user.username,
      email: user.email,
      fullName: user.fullName,
      role: user.role,
      isActive: user.isActive,
      createdAt: user.createdAt,
      lastLoginAt: user.lastLoginAt,
    );
  }

  /// Validates pre-registered user credentials.
  static UserAccount authenticateUser({
    required List<UserAccount> users,
    required String usernameOrEmail,
    required String password,
    String? nowIso,
  }) {
    final String identifier = usernameOrEmail.trim().toLowerCase();
    if (identifier.isEmpty || password.isEmpty) {
      throw const AppDomainError(
        code: 'VALIDATION_ERROR',
        message: 'Username/email and password are required.',
        status: 400,
      );
    }

    UserAccount? matched;
    for (final UserAccount u in users) {
      final isLegacyOrEfaAdminAlias = u.id == 'USR-ADMIN-001' &&
          (identifier == 'admin@efa.local' ||
              identifier == 'admin@senayerp.local');
      if (u.username.toLowerCase() == identifier ||
          u.email.toLowerCase() == identifier ||
          isLegacyOrEfaAdminAlias) {
        matched = u;
        break;
      }
    }

    if (matched == null) {
      throw const AppDomainError(
        code: 'INVALID_CREDENTIALS',
        message: 'Invalid username/email or password.',
        status: 401,
      );
    }
    if (!matched.isActive) {
      throw const AppDomainError(
        code: 'ACCOUNT_DEACTIVATED',
        message:
            'This account has been deactivated. Contact the administrator.',
        status: 403,
      );
    }
    if (!verifyPassword(password, matched.passwordHash)) {
      throw const AppDomainError(
        code: 'INVALID_CREDENTIALS',
        message: 'Invalid username/email or password.',
        status: 401,
      );
    }

    final String loginTime = nowIso ?? DateTime.now().toUtc().toIso8601String();
    return matched.copyWith(lastLoginAt: loginTime);
  }

  /// Creates a new authorized user account (Admin action).
  static ({List<UserAccount> users, UserAccount created}) createUserAccount({
    required List<UserAccount> users,
    required CreateUserInput input,
    String? nowIso,
  }) {
    final String username = input.username.trim().toLowerCase();
    final String email = input.email.trim().toLowerCase();
    final String fullName = input.fullName.trim();
    final String password = input.password;

    if (username.length < 3) {
      throw const AppDomainError(
        code: 'VALIDATION_ERROR',
        message: 'Username must be at least 3 characters.',
        status: 400,
      );
    }
    if (!email.contains('@') || email.length < 5) {
      throw const AppDomainError(
        code: 'VALIDATION_ERROR',
        message: 'A valid email address is required.',
        status: 400,
      );
    }
    if (fullName.isEmpty) {
      throw const AppDomainError(
        code: 'VALIDATION_ERROR',
        message: 'Full name is required.',
        status: 400,
      );
    }
    if (password.length < 8) {
      throw const AppDomainError(
        code: 'VALIDATION_ERROR',
        message: 'Password must be at least 8 characters.',
        status: 400,
      );
    }

    final bool duplicate = users.any(
      (u) =>
          u.username.toLowerCase() == username ||
          u.email.toLowerCase() == email,
    );
    if (duplicate) {
      throw const AppDomainError(
        code: 'DUPLICATE_USER',
        message: 'A user with this username or email already exists.',
        status: 409,
      );
    }

    final String timestamp = nowIso ?? DateTime.now().toUtc().toIso8601String();
    final UserAccount created = UserAccount(
      id: 'USR-${DateTime.now().millisecondsSinceEpoch}-${generateRandomHex(2).toUpperCase()}',
      username: username,
      email: email,
      fullName: fullName,
      role: input.role,
      passwordHash: hashPassword(password),
      isActive: true,
      createdAt: timestamp,
    );

    return (users: <UserAccount>[...users, created], created: created);
  }

  /// Activates or deactivates a user account while protecting the last active administrator.
  static List<UserAccount> toggleUserStatus({
    required List<UserAccount> users,
    required String targetUserId,
    required bool isActive,
    required String actorUserId,
  }) {
    final int idx = users.indexWhere((u) => u.id == targetUserId);
    if (idx < 0) {
      throw const AppDomainError(
        code: 'USER_NOT_FOUND',
        message: 'User account not found.',
        status: 404,
      );
    }
    final UserAccount target = users[idx];

    if (!isActive && target.id == actorUserId) {
      throw const AppDomainError(
        code: 'SELF_MODIFICATION_FORBIDDEN',
        message: 'You cannot deactivate your own currently active account.',
        status: 409,
      );
    }

    if (!isActive && target.role == UserRole.admin && target.isActive) {
      final int activeAdmins = users
          .where((u) => u.role == UserRole.admin && u.isActive)
          .length;
      if (activeAdmins <= 1) {
        throw const AppDomainError(
          code: 'LAST_ADMIN_PROTECTION',
          message: 'Cannot deactivate the last active administrator account.',
          status: 409,
        );
      }
    }

    final List<UserAccount> updated = List<UserAccount>.from(users);
    updated[idx] = target.copyWith(isActive: isActive);
    return updated;
  }

  /// Deletes a user account while preventing self-deletion and last-admin deletion.
  static List<UserAccount> deleteUserAccount({
    required List<UserAccount> users,
    required String targetUserId,
    required String actorUserId,
  }) {
    final int idx = users.indexWhere((u) => u.id == targetUserId);
    if (idx < 0) {
      throw const AppDomainError(
        code: 'USER_NOT_FOUND',
        message: 'User account not found.',
        status: 404,
      );
    }
    final UserAccount target = users[idx];

    if (target.id == actorUserId) {
      throw const AppDomainError(
        code: 'SELF_MODIFICATION_FORBIDDEN',
        message: 'You cannot delete your own currently logged-in account.',
        status: 409,
      );
    }

    if (target.role == UserRole.admin && target.isActive) {
      final int activeAdmins = users
          .where((u) => u.role == UserRole.admin && u.isActive)
          .length;
      if (activeAdmins <= 1) {
        throw const AppDomainError(
          code: 'LAST_ADMIN_PROTECTION',
          message: 'Cannot delete the last active administrator account.',
          status: 409,
        );
      }
    }

    return users.where((u) => u.id != targetUserId).toList();
  }
}
