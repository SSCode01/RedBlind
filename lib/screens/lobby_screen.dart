// lib/screens/lobby_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_model.dart';
import '../services/auth_service.dart';
import '../services/game_service.dart';
import '../theme/app_theme.dart';
import '../widgets/poker_background.dart';
import '../widgets/glass_card.dart';
import 'game_screen.dart';

class LobbyScreen extends StatefulWidget {
  final String gameId;

  const LobbyScreen({super.key, required this.gameId});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final _authService = AuthService();
  final _gameService = GameService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GameModel?>(
      stream: _gameService.gameStream(widget.gameId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.nearBlack,
            body: Center(child: CircularProgressIndicator(color: AppColors.crimson)),
          );
        }

        final game = snapshot.data;
        if (game == null) {
          return const Scaffold(
            backgroundColor: AppColors.nearBlack,
            body: Center(
              child: Text('Game not found', style: TextStyle(color: Colors.white)),
            ),
          );
        }

        // Auto-navigate when game starts
        if (game.status == GameStatus.active) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => GameScreen(gameId: game.gameId)),
            );
          });
        }

        final uid = _authService.currentUser?.uid;
        final isHost = game.hostId == uid;

        return Scaffold(
          body: PokerBackground(
            child: SafeArea(
              child: Column(
                children: [
                  _buildAppBar(game, isHost),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildRoomCode(game.roomCode),
                          const SizedBox(height: 28),
                          _buildWaitingBanner(game.players.length),
                          const SizedBox(height: 28),
                          _buildPlayerList(game, uid),
                          const SizedBox(height: 28),
                          if (isHost) _buildStartButton(game),
                          if (!isHost) _buildWaitingForHost(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(GameModel game, bool isHost) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  game.gameName,
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Buy-in: \$${game.buyIn.toStringAsFixed(0)} per player',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isHost)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.textGold.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.textGold.withOpacity(0.5)),
              ),
              child: const Text(
                'HOST',
                style: TextStyle(
                  color: AppColors.textGold,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            )
          else
            const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildRoomCode(String code) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.share, color: AppColors.textMuted, size: 16),
              const SizedBox(width: 8),
              Text(
                'ROOM CODE',
                style: GoogleFonts.raleway(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                code,
                style: GoogleFonts.raleway(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 12,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Room code copied!'),
                      backgroundColor: AppColors.deepRed,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy, color: AppColors.crimson, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Share this code with friends to join',
            style: GoogleFonts.raleway(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildWaitingBanner(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 8,
            height: 8,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.positive,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$count player${count != 1 ? 's' : ''} in the lobby',
            style: GoogleFonts.raleway(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerList(GameModel game, String? uid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PLAYERS',
          style: GoogleFonts.raleway(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        ...game.players.asMap().entries.map((entry) {
          final i = entry.key;
          final player = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              borderColor: player.uid == uid
                  ? AppColors.crimson.withOpacity(0.5)
                  : AppColors.glassBorder,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: player.isHost
                            ? [AppColors.textGold, Colors.orange]
                            : [AppColors.crimson, AppColors.deepRed],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        player.displayName.isNotEmpty
                            ? player.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      player.displayName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (player.isHost)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.textGold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppColors.textGold.withOpacity(0.5)),
                      ),
                      child: const Text(
                        '👑 HOST',
                        style: TextStyle(
                          color: AppColors.textGold,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    )
                  else if (player.uid == uid)
                    const Text(
                      'YOU',
                      style: TextStyle(
                        color: AppColors.crimson,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: Duration(milliseconds: 300 + i * 100))
                .slideX(begin: 0.2, end: 0),
          );
        }),
      ],
    );
  }

  Widget _buildStartButton(GameModel game) {
    final canStart = game.players.length >= 2;
    return Column(
      children: [
        if (!canStart)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Need at least 2 players to start',
              style: GoogleFonts.raleway(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
          ),
        RedGlowButton(
          label: 'START GAME',
          icon: Icons.play_arrow,
          onTap: canStart
              ? () async {
                  await _gameService.startGame(game.gameId);
                }
              : null,
          color: canStart ? AppColors.crimson : AppColors.textMuted,
        ),
      ],
    ).animate().fadeIn(delay: 700.ms);
  }

  Widget _buildWaitingForHost() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.textGold,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Waiting for host to start the game...',
            style: GoogleFonts.raleway(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 700.ms);
  }
}