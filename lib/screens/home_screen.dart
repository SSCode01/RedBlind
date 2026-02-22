// lib/screens/home_screen.dart
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
import 'login_screen.dart';
import 'signup_screen.dart';
import 'lobby_screen.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _gameService = GameService();
  bool _isLoadingGames = true;
  List<GameModel> _activeGames = [];

  @override
  void initState() {
    super.initState();
    _loadActiveGames();
  }

  Future<void> _loadActiveGames() async {
    if (_authService.currentUser == null) return;
    final games = await _gameService
        .getActiveGamesForUser(_authService.currentUser!.uid);
    if (mounted) {
      setState(() {
        _activeGames = games;
        _isLoadingGames = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PokerBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 40),
                _buildMainActions(),
                const SizedBox(height: 36),
                if (_activeGames.isNotEmpty) ...[
                  _buildActiveGames(),
                ],
                _buildPokerTip(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final name = _authService.displayName;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: GoogleFonts.raleway(
                color: AppColors.textSecondary,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              name,
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2),
        Row(
          children: [
            IconButton(
              onPressed: _loadActiveGames,
              icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            ),
            GestureDetector(
              onTap: _signOut,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.glassWhite,
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: const Icon(
                  Icons.logout,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  Widget _buildMainActions() {
    return Column(
      children: [
        // LOGO / brand center
        Center(
          child: Column(
            children: [
              Text(
                '♠  ♥  ♦  ♣',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white.withOpacity(0.15),
                  fontSize: 28,
                  letterSpacing: 12,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'REDBLIND',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 1,
                width: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.transparent,
                    AppColors.crimson,
                    Colors.transparent,
                  ]),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 300.ms, duration: 700.ms),
        const SizedBox(height: 36),

        // Create Table button - BIG
        GestureDetector(
          onTap: _showCreateTableDialog,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFCC0000), Color(0xFF8B0000)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.crimson.withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: -5,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.add_circle_outline,
                    color: Colors.white, size: 36),
                const SizedBox(height: 8),
                Text(
                  'CREATE TABLE',
                  style: GoogleFonts.raleway(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Start a new game as host',
                  style: GoogleFonts.raleway(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 500.ms, duration: 600.ms)
            .slideY(begin: 0.3, end: 0),

        const SizedBox(height: 16),

        // Join Table button
        GestureDetector(
          onTap: _showJoinTableDialog,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.crimson.withOpacity(0.5),
                width: 1.5,
              ),
              color: AppColors.glassRed,
            ),
            child: Column(
              children: [
                const Icon(Icons.meeting_room_outlined,
                    color: AppColors.crimson, size: 32),
                const SizedBox(height: 8),
                Text(
                  'JOIN TABLE',
                  style: GoogleFonts.raleway(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enter a room code to join',
                  style: GoogleFonts.raleway(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 650.ms, duration: 600.ms)
            .slideY(begin: 0.3, end: 0),
      ],
    );
  }

  Widget _buildActiveGames() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.fiber_manual_record,
                color: AppColors.positive, size: 10),
            const SizedBox(width: 8),
            Text(
              'ACTIVE GAMES',
              style: GoogleFonts.raleway(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ],
        ).animate().fadeIn(delay: 800.ms),
        const SizedBox(height: 12),
        ..._activeGames.map((game) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildActiveGameCard(game),
            )),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildActiveGameCard(GameModel game) {
    final uid = _authService.currentUser?.uid;
    final isHost = game.hostId == uid;
    final myPlayer = game.players.where((p) => p.uid == uid).firstOrNull;

    return GlassCard(
      onTap: () => _resumeGame(game),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.feltGreen.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.table_restaurant,
                color: AppColors.feltGreenAccent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.gameName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${game.players.length} players · \$${game.buyIn.toStringAsFixed(0)} buy-in · ${game.roomCode}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: game.status == GameStatus.active
                      ? AppColors.positive.withOpacity(0.2)
                      : AppColors.neutral.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  game.status == GameStatus.active ? 'LIVE' : 'LOBBY',
                  style: TextStyle(
                    color: game.status == GameStatus.active
                        ? AppColors.positive
                        : AppColors.neutral,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'RESUME →',
                style: GoogleFonts.raleway(
                  color: AppColors.crimson,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 850.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildPokerTip() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Chips are virtual. Only balances are tracked. No gambling involved.',
              style: GoogleFonts.raleway(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 1000.ms);
  }

  void _showCreateTableDialog() {
    final nameCtrl = TextEditingController(text: 'Poker Night');
    final buyInCtrl = TextEditingController(text: '100');
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: GlassCard(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            padding: const EdgeInsets.all(28),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.table_restaurant, color: AppColors.crimson),
                      const SizedBox(width: 10),
                      Text(
                        'Create New Table',
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: nameCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Game Name',
                      prefixIcon: Icon(Icons.edit_outlined, size: 20),
                    ),
                    validator: (v) => v?.isEmpty == true ? 'Enter a name' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: buyInCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Buy-In Amount (\$)',
                      prefixIcon: Icon(Icons.attach_money, size: 20),
                    ),
                    validator: (v) {
                      if (v?.isEmpty == true) return 'Enter buy-in';
                      if (double.tryParse(v!) == null || double.parse(v) <= 0) {
                        return 'Enter valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),
                  RedGlowButton(
                    label: isLoading ? '' : 'CREATE TABLE',
                    isLoading: isLoading,
                    icon: Icons.add,
                    onTap: () async {
                      if (!formKey.currentState!.validate()) return;
                      setModalState(() => isLoading = true);
                      try {
                        final game = await _gameService.createGame(
                          hostId: _authService.currentUser!.uid,
                          hostName: _authService.displayName,
                          buyIn: double.parse(buyInCtrl.text),
                          gameName: nameCtrl.text.trim(),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LobbyScreen(gameId: game.gameId),
                            ),
                          );
                        }
                      } catch (e) {
                        setModalState(() => isLoading = false);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showJoinTableDialog() {
    final codeCtrl = TextEditingController();
    bool isLoading = false;
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: GlassCard(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.meeting_room_outlined, color: AppColors.crimson),
                    const SizedBox(width: 10),
                    Text(
                      'Join a Table',
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter the 6-character room code shared by the host.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  style: GoogleFonts.raleway(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 8,
                  ),
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  decoration: InputDecoration(
                    hintText: 'XXXXXX',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 28,
                      letterSpacing: 8,
                    ),
                    counterText: '',
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    error!,
                    style: const TextStyle(
                        color: AppColors.negative, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 24),
                RedGlowButton(
                  label: 'JOIN TABLE',
                  icon: Icons.arrow_forward,
                  isLoading: isLoading,
                  onTap: () async {
                    if (codeCtrl.text.length < 4) return;
                    setModalState(() {
                      isLoading = true;
                      error = null;
                    });
                    try {
                      final game = await _gameService.joinGame(
                        roomCode: codeCtrl.text,
                        playerId: _authService.currentUser!.uid,
                        playerName: _authService.displayName,
                      );
                      if (game == null) {
                        setModalState(() {
                          error = 'Room not found or game already started.';
                          isLoading = false;
                        });
                        return;
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LobbyScreen(gameId: game.gameId),
                          ),
                        );
                      }
                    } catch (e) {
                      setModalState(() {
                        error = 'Failed to join. Try again.';
                        isLoading = false;
                      });
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

  void _resumeGame(GameModel game) {
    if (game.status == GameStatus.waiting) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LobbyScreen(gameId: game.gameId)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GameScreen(gameId: game.gameId)),
      );
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }
}