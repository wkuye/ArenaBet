class UserModel {
  final String username;
  final String walletAddress;
  final String uid;
  final double suiBalance;
  final double lockedBalance;

  UserModel({
    required this.username,
    required this.walletAddress,
    required this.uid,
    required this.suiBalance,
    this.lockedBalance = 0.0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json['username'] ?? '',
      walletAddress: json['walletAddress'] ?? '',
      uid: json['uid'] ?? '',
      suiBalance: (json['suiBalance'] ?? 0.0).toDouble(),
      lockedBalance: (json['lockedBalance'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'walletAddress': walletAddress,
      'uid': uid,
      'suiBalance': suiBalance,
      'lockedBalance': lockedBalance,
    };
  }
}