/// TOTP账户模型类
/// 用于存储2FA身份验证账户的信息
class TotpAccount {
  /// 账户唯一标识符
  final String id;

  /// 账户名称（如：Google、GitHub等）
  final String name;

  /// 账户用户名或邮箱
  final String account;

  /// Base32编码的密钥
  final String secret;

  /// 发行者名称
  final String issuer;

  /// 时间间隔（秒），默认30秒
  final int period;

  /// OTP位数，默认6位
  final int digits;

  /// 算法类型，默认SHA1
  final String algorithm;

  /// 创建时间
  final DateTime createdAt;

  /// 最后修改时间
  final DateTime updatedAt;

  const TotpAccount({
    required this.id,
    required this.name,
    required this.account,
    required this.secret,
    required this.issuer,
    this.period = 30,
    this.digits = 6,
    this.algorithm = 'SHA1',
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从Map创建TotpAccount实例
  factory TotpAccount.fromMap(Map<String, dynamic> map) {
    return TotpAccount(
      id: map['id'] as String,
      name: map['name'] as String,
      account: map['account'] as String,
      secret: map['secret'] as String,
      issuer: map['issuer'] as String,
      period: map['period'] as int? ?? 30,
      digits: map['digits'] as int? ?? 6,
      algorithm: map['algorithm'] as String? ?? 'SHA1',
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'account': account,
      'secret': secret,
      'issuer': issuer,
      'period': period,
      'digits': digits,
      'algorithm': algorithm,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 复制并修改部分属性
  TotpAccount copyWith({
    String? id,
    String? name,
    String? account,
    String? secret,
    String? issuer,
    int? period,
    int? digits,
    String? algorithm,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TotpAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      account: account ?? this.account,
      secret: secret ?? this.secret,
      issuer: issuer ?? this.issuer,
      period: period ?? this.period,
      digits: digits ?? this.digits,
      algorithm: algorithm ?? this.algorithm,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TotpAccount && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TotpAccount(id: $id, name: $name, account: $account, issuer: $issuer)';
  }
}
