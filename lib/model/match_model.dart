class MatchModel {
  final double bet;
  final String? player1;
  final String? player2;
  final String ?matched;

  MatchModel({
    required this.bet,
    required this.player1,
    required this.player2,
    required this.matched,
  });
  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      bet: json['bet'],
      player1: json['player1'],
      player2: json['player2'],
      matched: json['matched'],
    );
  }
}
