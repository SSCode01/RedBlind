// lib/models/game_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerModel {
  final String uid;
  final String displayName;
  final double balance;
  final double totalBuyIn;
  final bool isHost;
  final bool isActive;

  PlayerModel({
    required this.uid,
    required this.displayName,
    required this.balance,
    required this.totalBuyIn,
    this.isHost = false,
    this.isActive = true,
  });

  factory PlayerModel.fromMap(Map<String, dynamic> map) {
    return PlayerModel(
      uid: map['uid'] ?? '',
      displayName: map['displayName'] ?? 'Player',
      balance: (map['balance'] ?? 0).toDouble(),
      totalBuyIn: (map['totalBuyIn'] ?? 0).toDouble(),
      isHost: map['isHost'] ?? false,
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'balance': balance,
      'totalBuyIn': totalBuyIn,
      'isHost': isHost,
      'isActive': isActive,
    };
  }

  PlayerModel copyWith({
    double? balance,
    double? totalBuyIn,
    bool? isActive,
  }) {
    return PlayerModel(
      uid: uid,
      displayName: displayName,
      balance: balance ?? this.balance,
      totalBuyIn: totalBuyIn ?? this.totalBuyIn,
      isHost: isHost,
      isActive: isActive ?? this.isActive,
    );
  }

  double get netProfit => balance - totalBuyIn;
}

enum GameStatus { waiting, active, finished }

class GameModel {
  final String gameId;
  final String hostId;
  final String roomCode;
  final double buyIn;
  final List<PlayerModel> players;
  final GameStatus status;
  final DateTime createdAt;
  final String gameName;

  GameModel({
    required this.gameId,
    required this.hostId,
    required this.roomCode,
    required this.buyIn,
    required this.players,
    required this.status,
    required this.createdAt,
    required this.gameName,
  });

  factory GameModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GameModel(
      gameId: doc.id,
      hostId: data['hostId'] ?? '',
      roomCode: data['roomCode'] ?? '',
      buyIn: (data['buyIn'] ?? 0).toDouble(),
      players: (data['players'] as List<dynamic>? ?? [])
          .map((p) => PlayerModel.fromMap(p as Map<String, dynamic>))
          .toList(),
      status: GameStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => GameStatus.waiting,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      gameName: data['gameName'] ?? 'Poker Night',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hostId': hostId,
      'roomCode': roomCode,
      'buyIn': buyIn,
      'players': players.map((p) => p.toMap()).toList(),
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'gameName': gameName,
    };
  }
}

class RoundModel {
  final String roundId;
  final List<String> winnerIds;
  final double pot;
  final DateTime timestamp;
  final String note;

  RoundModel({
    required this.roundId,
    required this.winnerIds,
    required this.pot,
    required this.timestamp,
    this.note = '',
  });

  factory RoundModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoundModel(
      roundId: doc.id,
      winnerIds: List<String>.from(data['winnerIds'] ?? []),
      pot: (data['pot'] ?? 0).toDouble(),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: data['note'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'winnerIds': winnerIds,
      'pot': pot,
      'timestamp': Timestamp.fromDate(timestamp),
      'note': note,
    };
  }
}

class SettlementEntry {
  final String fromPlayerName;
  final String toPlayerName;
  final double amount;

  SettlementEntry({
    required this.fromPlayerName,
    required this.toPlayerName,
    required this.amount,
  });
}