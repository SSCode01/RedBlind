// lib/screens/settlement_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_model.dart';
import '../services/auth_service.dart';
import '../services/game_service.dart';
import '../theme/app_theme.dart';
import '../widgets/poker_background.dart';
import '../widgets/glass_card.dart';
import 'home_screen.dart';

class SettlementScreen extends StatefulWidget {
  final String gameId;

  const SettlementScreen({super.key, required this.gameId});

  @override
  State<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends State<SettlementScreen> {
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
            body: Center(
              child: CircularProgressIndicator(color: AppColors.crimson),
            ),
          );
        }

        final game = snapshot.data;
        if (game == null) {
          return Scaffold(
            backgroundColor: AppColors.nearBlack,
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Home'),
              ),
            ),
          );
        }

        final settlements = _gameService.calculateSettlements(game.players);
        final uid = _authService.currentUser?.uid;
        final myPlayer = game.players.where((p) => p.uid == uid).firstOrNull;

        // Sort players by net profit desc
        final sorted = [...game.players]
          ..sort((a, b) => b.netProfit.compareTo(a.netProfit));

        return Scaffold(
          body: PokerBackground(
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(game),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Column(
                        children: [
                          if (myPlayer != null) _buildMyResult(myPlayer),
                          const SizedBox(height: 24),
                          _buildFinalStandings(sorted, uid),
                          const SizedBox(height: 24),
                          _buildSettlements(settlements),
                          const SizedBox(height: 32),
                          _buildGoHomeButton(),
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

  Widget _buildHeader(GameModel game) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 48))
              .animate()
              .scale(
                  begin: const Offset(0, 0),
                  duration: 800.ms,
                  curve: Curves.elasticOut)
              .fadeIn(),
          const SizedBox(height: 8),
          Text(
            'Game Over',
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w700,
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
          const SizedBox(height: 4),
          Text(
            game.gameName,
            style: GoogleFonts.raleway(
              color: AppColors.textMuted,
              fontSize: 14,
              letterSpacing: 1,
            ),
          ).animate().fadeIn(delay: 500.ms),
        ],
      ),
    );
  }

  Widget _buildMyResult(PlayerModel player) {
    final net = player.netProfit;
    final isPositive = net >= 0;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderColor: isPositive
          ? AppColors.positive.withOpacity(0.5)
          : AppColors.negative.withOpacity(0.5),
      color: isPositive
          ? AppColors.positive.withOpacity(0.08)
          : AppColors.negative.withOpacity(0.08),
      child: Column(
        children: [
          Text(
            'YOUR RESULT',
            style: GoogleFonts.raleway(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isPositive ? '🎉' : '😔',
            style: const TextStyle(fontSize: 36),
          ),
          const SizedBox(height: 8),
          Text(
            '${isPositive ? '+' : ''}\$${net.toStringAsFixed(2)}',
            style: TextStyle(
              color: isPositive ? AppColors.positive : AppColors.negative,
              fontSize: 40,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isPositive
                ? 'You profited \$${net.toStringAsFixed(2)}!'
                : 'You lost \$${net.abs().toStringAsFixed(2)}',
            style: GoogleFonts.raleway(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Final balance: \$${player.balance.toStringAsFixed(2)} · Buy-in: \$${player.totalBuyIn.toStringAsFixed(2)}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildFinalStandings(List<PlayerModel> players, String? uid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FINAL STANDINGS',
          style: GoogleFonts.raleway(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        ...players.asMap().entries.map((entry) {
          final rank = entry.key;
          final player = entry.value;
          final net = player.netProfit;
          final isPositive = net >= 0;
          final isCurrentUser = player.uid == uid;
          final medals = ['🥇', '🥈', '🥉'];

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              borderColor: isCurrentUser
                  ? AppColors.crimson.withOpacity(0.5)
                  : AppColors.glassBorder,
              child: Row(
                children: [
                  Text(
                    rank < 3 ? medals[rank] : '#${rank + 1}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      player.displayName + (isCurrentUser ? ' (You)' : ''),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${player.balance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${isPositive ? '+' : ''}\$${net.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: isPositive
                              ? AppColors.positive
                              : AppColors.negative,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: 700 + rank * 100));
        }),
      ],
    );
  }

  Widget _buildSettlements(List<SettlementEntry> settlements) {
    if (settlements.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline,
                color: AppColors.positive, size: 32),
            const SizedBox(height: 8),
            Text(
              'All squared up!',
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'No payments needed.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 900.ms);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'SETTLEMENTS',
              style: GoogleFonts.raleway(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.neutral.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${settlements.length} transaction${settlements.length != 1 ? 's' : ''}',
                style: const TextStyle(
                  color: AppColors.neutral,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Minimized to fewest transactions',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        ...settlements.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              borderColor: AppColors.neutral.withOpacity(0.3),
              child: Row(
                children: [
                  const Text('💸', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.raleway(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: s.fromPlayerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.negative,
                                ),
                              ),
                              const TextSpan(text: '  →  '),
                              TextSpan(
                                text: s.toPlayerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.positive,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${s.fromPlayerName} owes ${s.toPlayerName}',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${s.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.textGold,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: 900 + i * 100)).slideX(begin: 0.1);
        }),
      ],
    );
  }

  Widget _buildGoHomeButton() {
    return RedGlowButton(
      label: 'BACK TO HOME',
      icon: Icons.home_outlined,
      onTap: () {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      },
    ).animate().fadeIn(delay: 1200.ms);
  }
}