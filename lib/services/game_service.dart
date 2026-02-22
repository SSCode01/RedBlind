// lib/services/game_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/game_model.dart';

class GameService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Generate a 6-character room code
  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = List.generate(6, (i) => chars[DateTime.now().microsecond % chars.length + i % chars.length < chars.length ? DateTime.now().microsecond % chars.length + i % chars.length : i % chars.length]);
    return random.join();
  }

  // Create a new game
  Future<GameModel> createGame({
    required String hostId,
    required String hostName,
    required double buyIn,
    required String gameName,
  }) async {
    final gameId = _uuid.v4();
    final roomCode = _generateRoomCode();

    final hostPlayer = PlayerModel(
      uid: hostId,
      displayName: hostName,
      balance: buyIn,
      totalBuyIn: buyIn,
      isHost: true,
    );

    final game = GameModel(
      gameId: gameId,
      hostId: hostId,
      roomCode: roomCode,
      buyIn: buyIn,
      players: [hostPlayer],
      status: GameStatus.waiting,
      createdAt: DateTime.now(),
      gameName: gameName,
    );

    await _db.collection('games').doc(gameId).set(game.toMap());
    return game;
  }

  // Join a game by room code
  Future<GameModel?> joinGame({
    required String roomCode,
    required String playerId,
    required String playerName,
  }) async {
    final query = await _db
        .collection('games')
        .where('roomCode', isEqualTo: roomCode.toUpperCase())
        .where('status', isEqualTo: 'waiting')
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final doc = query.docs.first;
    final game = GameModel.fromFirestore(doc);

    // Check if player already in game
    if (game.players.any((p) => p.uid == playerId)) return game;

    final newPlayer = PlayerModel(
      uid: playerId,
      displayName: playerName,
      balance: game.buyIn,
      totalBuyIn: game.buyIn,
    );

    final updatedPlayers = [...game.players, newPlayer];
    await _db.collection('games').doc(game.gameId).update({
      'players': updatedPlayers.map((p) => p.toMap()).toList(),
    });

    return game;
  }

  // Start the game (host only)
  Future<void> startGame(String gameId) async {
    await _db.collection('games').doc(gameId).update({
      'status': GameStatus.active.name,
    });
  }

  // Record a round result - deduct from all, add to winner(s)
  Future<void> recordRound({
    required String gameId,
    required List<PlayerModel> allPlayers,
    required List<String> winnerIds,
    required double pot,
    String note = '',
  }) async {
    final roundId = _uuid.v4();
    final winAmount = pot / winnerIds.length;

    // Update player balances
    final updatedPlayers = allPlayers.map((player) {
      double newBalance = player.balance;
      // Winners receive their share
      if (winnerIds.contains(player.uid)) {
        newBalance += winAmount;
      }
      // Pot was already "in the middle" - the deductions happen at buy-in
      // Actually in chipless poker: all active players contributed equally
      // Pot = sum of contributions. We track by deducting from losers.
      // Simpler model: track winner gains, losers lose proportionally
      return player;
    }).toList();

    // More accurate: pot comes from all other players equally
    final loserIds = allPlayers
        .where((p) => !winnerIds.contains(p.uid) && p.isActive)
        .map((p) => p.uid)
        .toList();

    final perLoser = loserIds.isEmpty ? 0.0 : pot / loserIds.length;

    final finalPlayers = allPlayers.map((player) {
      double newBalance = player.balance;
      if (winnerIds.contains(player.uid)) {
        newBalance += winAmount;
      } else if (loserIds.contains(player.uid)) {
        newBalance -= perLoser;
      }
      return player.copyWith(balance: newBalance);
    }).toList();

    final batch = _db.batch();

    // Update game players
    batch.update(_db.collection('games').doc(gameId), {
      'players': finalPlayers.map((p) => p.toMap()).toList(),
    });

    // Add round subcollection
    final roundRef = _db
        .collection('games')
        .doc(gameId)
        .collection('rounds')
        .doc(roundId);

    batch.set(roundRef, {
      'winnerIds': winnerIds,
      'pot': pot,
      'timestamp': FieldValue.serverTimestamp(),
      'note': note,
    });

    await batch.commit();
  }

  // Player buys back in
  Future<void> reBuyIn({
    required String gameId,
    required List<PlayerModel> allPlayers,
    required String playerId,
    required double amount,
  }) async {
    final updatedPlayers = allPlayers.map((p) {
      if (p.uid == playerId) {
        return p.copyWith(
          balance: p.balance + amount,
          totalBuyIn: p.totalBuyIn + amount,
        );
      }
      return p;
    }).toList();

    await _db.collection('games').doc(gameId).update({
      'players': updatedPlayers.map((p) => p.toMap()).toList(),
    });
  }

  // End game
  Future<void> endGame(String gameId) async {
    await _db.collection('games').doc(gameId).update({
      'status': GameStatus.finished.name,
    });
  }

  // Real-time game stream
  Stream<GameModel?> gameStream(String gameId) {
    return _db
        .collection('games')
        .doc(gameId)
        .snapshots()
        .map((doc) => doc.exists ? GameModel.fromFirestore(doc) : null);
  }

  // Get rounds for a game
  Stream<List<RoundModel>> roundsStream(String gameId) {
    return _db
        .collection('games')
        .doc(gameId)
        .collection('rounds')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => RoundModel.fromFirestore(d)).toList());
  }

  // Calculate settlements (minimize transactions)
  List<SettlementEntry> calculateSettlements(List<PlayerModel> players) {
    // Net profit/loss per player
    final netMap = <String, double>{};
    final nameMap = <String, String>{};

    for (final p in players) {
      netMap[p.uid] = p.netProfit;
      nameMap[p.uid] = p.displayName;
    }

    final creditors = netMap.entries
        .where((e) => e.value > 0)
        .map((e) => MapEntry(e.key, e.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final debtors = netMap.entries
        .where((e) => e.value < 0)
        .map((e) => MapEntry(e.key, e.value.abs()))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final settlements = <SettlementEntry>[];
    int i = 0, j = 0;

    final creditorAmounts = creditors.map((e) => e.value).toList();
    final debtorAmounts = debtors.map((e) => e.value).toList();

    while (i < creditors.length && j < debtors.length) {
      final amount = creditorAmounts[i] < debtorAmounts[j]
          ? creditorAmounts[i]
          : debtorAmounts[j];

      settlements.add(SettlementEntry(
        fromPlayerName: nameMap[debtors[j].key]!,
        toPlayerName: nameMap[creditors[i].key]!,
        amount: double.parse(amount.toStringAsFixed(2)),
      ));

      creditorAmounts[i] -= amount;
      debtorAmounts[j] -= amount;

      if (creditorAmounts[i] < 0.01) i++;
      if (debtorAmounts[j] < 0.01) j++;
    }

    return settlements;
  }

  // Get active games for a user
  Future<List<GameModel>> getActiveGamesForUser(String userId) async {
    final snap = await _db
        .collection('games')
        .where('status', whereIn: ['waiting', 'active'])
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get();

    return snap.docs
        .map((d) => GameModel.fromFirestore(d))
        .where((g) => g.players.any((p) => p.uid == userId))
        .toList();
  }
}