// lib/screens/game_screen.dart
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
import 'settlement_screen.dart';

class GameScreen extends StatefulWidget {
  final String gameId;

  const GameScreen({super.key, required this.gameId});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _gameService = GameService();
  late TabController _tabController;
  int _roundCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
          return Scaffold(
            backgroundColor: AppColors.nearBlack,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Game ended or not found',
                      style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Home'),
                  ),
                ],
              ),
            ),
          );
        }

        // Auto navigate to settlement
        if (game.status == GameStatus.finished) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => SettlementScreen(gameId: game.gameId),
              ),
            );
          });
        }

        final uid = _authService.currentUser?.uid;
        final isHost = game.hostId == uid;

        return Scaffold(
          body: PokerBackground(
            isGreenTable: true,
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(game, isHost),
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTableView(game, uid, isHost),
                        _buildRoundsView(game),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: isHost
              ? _buildHostFAB(game)
              : null,
        );
      },
    );
  }

  Widget _buildHeader(GameModel game, bool isHost) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios,
                color: Colors.white70, size: 20),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  game.gameName,
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.fiber_manual_record,
                        color: AppColors.positive, size: 8),
                    const SizedBox(width: 4),
                    Text(
                      'LIVE · ${game.players.length} players · \$${game.buyIn.toStringAsFixed(0)} buy-in',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isHost)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white70),
              color: AppColors.cardSurface,
              onSelected: (val) {
                if (val == 'end') _confirmEndGame(game);
                if (val == 'rebuy') _showReBuyDialog(game);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'rebuy',
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline,
                          color: AppColors.positive, size: 18),
                      SizedBox(width: 8),
                      Text('Re-buy Player',
                          style: TextStyle(color: AppColors.textPrimary)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'end',
                  child: Row(
                    children: [
                      Icon(Icons.stop_circle_outlined,
                          color: AppColors.negative, size: 18),
                      SizedBox(width: 8),
                      Text('End Game',
                          style: TextStyle(color: AppColors.negative)),
                    ],
                  ),
                ),
              ],
            )
          else
            const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.feltGreenAccent.withOpacity(0.4),
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle: GoogleFonts.raleway(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: 1,
        ),
        tabs: const [
          Tab(text: 'TABLE'),
          Tab(text: 'ROUNDS'),
        ],
      ),
    );
  }

  Widget _buildTableView(GameModel game, String? uid, bool isHost) {
    // Sort by balance descending
    final sorted = [...game.players]
      ..sort((a, b) => b.balance.compareTo(a.balance));

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
      children: [
        // Pot summary / totals
        _buildTotalsSummary(game),
        const SizedBox(height: 20),
        Text(
          'LEADERBOARD',
          style: GoogleFonts.raleway(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        ...sorted.asMap().entries.map((entry) {
          final rank = entry.key;
          final player = entry.value;
          final isCurrentUser = player.uid == uid;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildPlayerRow(player, rank, isCurrentUser),
          ).animate().fadeIn(delay: Duration(milliseconds: rank * 80));
        }),
        const SizedBox(height: 20),
        if (!isHost)
          GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.textMuted, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Only the host can record round results',
                  style: GoogleFonts.raleway(
                      color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTotalsSummary(GameModel game) {
    final totalInPlay = game.players.fold<double>(0, (s, p) => s + p.balance);
    final totalBuyIn = game.players.fold<double>(0, (s, p) => s + p.totalBuyIn);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      color: Colors.black.withOpacity(0.25),
      child: Row(
        children: [
          _buildStatItem('Total in Play', '\$${totalInPlay.toStringAsFixed(0)}', AppColors.textGold),
          _buildDivider(),
          _buildStatItem('Buy-ins', '\$${totalBuyIn.toStringAsFixed(0)}', AppColors.textSecondary),
          _buildDivider(),
          _buildStatItem('Players', '${game.players.length}', AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.white.withOpacity(0.1),
    );
  }

  Widget _buildPlayerRow(PlayerModel player, int rank, bool isCurrentUser) {
    final net = player.netProfit;
    final isPositive = net >= 0;
    final medals = ['🥇', '🥈', '🥉'];

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderColor: isCurrentUser
          ? AppColors.feltGreenAccent.withOpacity(0.6)
          : AppColors.glassBorder,
      color: isCurrentUser
          ? AppColors.feltGreen.withOpacity(0.15)
          : AppColors.glassWhite,
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              rank < 3 ? medals[rank] : '#${rank + 1}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: player.isHost
                    ? [AppColors.textGold, Colors.orange]
                    : isCurrentUser
                        ? [AppColors.feltGreenAccent, AppColors.feltGreen]
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
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      player.displayName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (player.isHost) ...[
                      const SizedBox(width: 6),
                      const Text('👑', style: TextStyle(fontSize: 12)),
                    ],
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.feltGreenAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            color: AppColors.feltGreenAccent,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  'Buy-in: \$${player.totalBuyIn.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
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
                  fontSize: 17,
                ),
              ),
              Text(
                '${isPositive ? '+' : ''}\$${net.toStringAsFixed(2)}',
                style: TextStyle(
                  color: isPositive ? AppColors.positive : AppColors.negative,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoundsView(GameModel game) {
    return StreamBuilder<List<RoundModel>>(
      stream: _gameService.roundsStream(game.gameId),
      builder: (context, snapshot) {
        final rounds = snapshot.data ?? [];

        if (rounds.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🃏', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  'No rounds played yet',
                  style: GoogleFonts.raleway(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Host records each round result',
                  style: GoogleFonts.raleway(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
          itemCount: rounds.length,
          itemBuilder: (context, i) {
            final round = rounds[i];
            final roundNum = rounds.length - i;
            final winnerNames = game.players
                .where((p) => round.winnerIds.contains(p.uid))
                .map((p) => p.displayName)
                .join(', ');

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.textGold.withOpacity(0.15),
                        border: Border.all(
                            color: AppColors.textGold.withOpacity(0.4)),
                      ),
                      child: Center(
                        child: Text(
                          '$roundNum',
                          style: const TextStyle(
                            color: AppColors.textGold,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('🏆 ', style: TextStyle(fontSize: 12)),
                              Flexible(
                                child: Text(
                                  winnerNames.isEmpty ? 'Unknown' : winnerNames,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (round.note.isNotEmpty)
                            Text(
                              round.note,
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '+\$${round.pot.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.positive,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: i * 60));
          },
        );
      },
    );
  }

  Widget _buildHostFAB(GameModel game) {
    return FloatingActionButton.extended(
      onPressed: () => _showRecordRoundSheet(game),
      backgroundColor: AppColors.crimson,
      elevation: 12,
      icon: const Icon(Icons.add, color: Colors.white),
      label: Text(
        'RECORD ROUND',
        style: GoogleFonts.raleway(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }

  void _showRecordRoundSheet(GameModel game) {
    final potCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final selectedWinners = <String>{};
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: GlassCard(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🃏', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Text(
                      'Record Round Result',
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Pot amount
                TextField(
                  controller: potCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Pot Amount (\$)',
                    prefixIcon: Icon(Icons.attach_money, size: 20),
                  ),
                ),
                const SizedBox(height: 16),

                // Winner selection
                Text(
                  'SELECT WINNER(S)',
                  style: GoogleFonts.raleway(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: game.players.map((player) {
                    final selected = selectedWinners.contains(player.uid);
                    return GestureDetector(
                      onTap: () => setModal(() {
                        if (selected) {
                          selectedWinners.remove(player.uid);
                        } else {
                          selectedWinners.add(player.uid);
                        }
                      }),
                      child: AnimatedContainer(
                        duration: 200.ms,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.textGold.withOpacity(0.2)
                              : AppColors.glassWhite,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: selected
                                ? AppColors.textGold
                                : AppColors.glassBorder,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (selected)
                              const Text('🏆 ',
                                  style: TextStyle(fontSize: 12)),
                            Text(
                              player.displayName,
                              style: TextStyle(
                                color: selected
                                    ? AppColors.textGold
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Optional note
                TextField(
                  controller: noteCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    prefixIcon: Icon(Icons.note_outlined, size: 20),
                    hintText: 'e.g. Full house',
                  ),
                ),
                const SizedBox(height: 24),

                RedGlowButton(
                  label: 'CONFIRM ROUND',
                  icon: Icons.check,
                  isLoading: isLoading,
                  onTap: selectedWinners.isEmpty ||
                          potCtrl.text.isEmpty
                      ? null
                      : () async {
                          final pot = double.tryParse(potCtrl.text);
                          if (pot == null || pot <= 0) return;

                          setModal(() => isLoading = true);
                          try {
                            await _gameService.recordRound(
                              gameId: game.gameId,
                              allPlayers: game.players,
                              winnerIds: selectedWinners.toList(),
                              pot: pot,
                              note: noteCtrl.text,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                          } catch (e) {
                            setModal(() => isLoading = false);
                          }
                        },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReBuyDialog(GameModel game) {
    String? selectedPlayerId;
    final amountCtrl =
        TextEditingController(text: game.buyIn.toStringAsFixed(0));
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => GlassCard(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Re-Buy In',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedPlayerId,
                dropdownColor: AppColors.cardSurface,
                decoration: const InputDecoration(
                  labelText: 'Select Player',
                  prefixIcon: Icon(Icons.person_outline, size: 20),
                ),
                items: game.players
                    .map((p) => DropdownMenuItem(
                          value: p.uid,
                          child: Text(p.displayName,
                              style:
                                  const TextStyle(color: AppColors.textPrimary)),
                        ))
                    .toList(),
                onChanged: (v) => setModal(() => selectedPlayerId = v),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Amount (\$)',
                  prefixIcon: Icon(Icons.attach_money, size: 20),
                ),
              ),
              const SizedBox(height: 24),
              RedGlowButton(
                label: 'CONFIRM RE-BUY',
                icon: Icons.add_circle_outline,
                isLoading: isLoading,
                color: AppColors.positive,
                onTap: selectedPlayerId == null ? null : () async {
                  final amount = double.tryParse(amountCtrl.text);
                  if (amount == null || amount <= 0) return;
                  setModal(() => isLoading = true);
                  await _gameService.reBuyIn(
                    gameId: game.gameId,
                    allPlayers: game.players,
                    playerId: selectedPlayerId!,
                    amount: amount,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmEndGame(GameModel game) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('End Game?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'This will finalize all balances and show the settlement screen.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _gameService.endGame(game.gameId);
            },
            child: const Text('End Game',
                style: TextStyle(color: AppColors.negative)),
          ),
        ],
      ),
    );
  }
}