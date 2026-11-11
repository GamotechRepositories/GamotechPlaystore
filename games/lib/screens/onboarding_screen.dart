import 'package:flutter/material.dart';

import '../services/onboarding_service.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.service = const OnboardingService()});

  final OnboardingService service;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _slideLabels = [
    'Favourite games',
    'Play with friends',
    'Join tournaments',
  ];
  bool _saving = false;
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    if (_saving) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _pageController.jumpToPage(page);
    } else {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _continue() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.service.complete();
      if (!mounted) return;
      Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save. Please try again.')),
      );
    }
  }

  Widget _getStartedButton(int index) {
    final isLast = index == _slideLabels.length - 1;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xFFFFF2B0), width: 2),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFF49A),
            Color(0xFFFFD44D),
            Color(0xFFF5A000),
            Color(0xFFFFD35B),
          ],
          stops: [0, 0.38, 0.78, 1],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0xAAFF7800), blurRadius: 24, spreadRadius: 1),
          BoxShadow(color: Color(0x55FFCC33), blurRadius: 6),
        ],
      ),
      child: TextButton(
        key: ValueKey(isLast ? 'Get Started' : 'Next'),
        onPressed: _saving
            ? null
            : (isLast ? _continue : () => _goToPage(index + 1)),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF1C0800),
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          overlayColor: Colors.white,
          shape: const StadiumBorder(),
        ),
        child: _saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  semanticsLabel: 'Opening sign in',
                ),
              )
            : Text(
                isLast ? 'Get Started' : 'Next',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
    );
  }

  Widget _gamesContent(double width) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Image.asset(
          'assets/images/card.png',
          width: width,
          height: width * 0.73,
          fit: BoxFit.contain,
          semanticLabel: 'Playing cards, Ludo pieces and casino chips',
        ),
        const SizedBox(height: 12),
        const CustomPaint(size: Size(68, 48), painter: _CrownPainter()),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Color(0xFFFFF5C3),
                Color(0xFFFFCE3B),
                Color(0xFFFFA600),
              ],
              stops: [0, 0.35, 0.7, 1],
            ).createShader(bounds),
            blendMode: BlendMode.srcIn,
            child: Text(
              'Play Your\nFavourite Games',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                height: 1.08,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: -0.8,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Ludo, Teen Patti, Rummy, Poker\n& more in one app.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 17, height: 1.35),
        ),
        const SizedBox(height: 8),
        const _SpadeDivider(),
      ],
    );
  }

  Widget _friendsContent(double width) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.white, Colors.transparent],
            stops: [0, 0.74, 1],
          ).createShader(bounds),
          blendMode: BlendMode.dstIn,
          child: Image.asset(
            'assets/images/frd.png',
            width: width,
            height: width * 1.02,
            fit: BoxFit.contain,
            semanticLabel: 'Friends celebrating and playing together online',
          ),
        ),
        Text(
          'Play with\nFriends Online',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            height: 1.1,
            color: const Color(0xFFFFF8E7),
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            shadows: const [Shadow(color: Color(0xAAFFAA33), blurRadius: 10)],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Create private rooms, invite friends\nand enjoy real-time matches.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 17, height: 1.4),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _tournamentsContent(double width) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        ClipRect(
          child: Align(
            // Reduce the empty space around the supplied transparent artwork.
            heightFactor: 0.78,
            alignment: const Alignment(0, 0.15),
            child: Image.asset(
              'assets/images/cup.png',
              width: width,
              height: width * 1.25,
              fit: BoxFit.contain,
              semanticLabel:
                  'Gold tournament trophy with laurels, a coin and a gaming chip',
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text.rich(
          const TextSpan(
            children: [
              TextSpan(text: 'Join Tournaments\n'),
              TextSpan(
                text: '& Win Big',
                style: TextStyle(color: Color(0xFFFFD86A)),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            height: 1.1,
            color: const Color(0xFFFFF8E7),
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            shadows: const [Shadow(color: Color(0xAAFFAA33), blurRadius: 10)],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Compete with real players,\nclimb the leaderboard and\nwin exciting rewards.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 17, height: 1.4),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _pageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_slideLabels.length, (index) {
        final selected = index == _currentPage;
        return Semantics(
          label:
              '${_slideLabels[index]}, slide ${index + 1} of ${_slideLabels.length}',
          selected: selected,
          child: SizedBox(
            width: 28,
            height: 48,
            child: Center(
              key: ValueKey('onboarding-dot-$index'),
              child: Container(
                width: selected ? 11 : 7,
                height: selected ? 11 : 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: selected
                        ? const [Color(0xFFFFF4A1), Color(0xFFFFB900)]
                        : const [Colors.white, Color(0xFFBDBDBD)],
                  ),
                  border: Border.all(
                    color: selected ? const Color(0xFFFFE984) : Colors.white70,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _slide(int index, BoxConstraints viewport) {
    return SingleChildScrollView(
      key: PageStorageKey('onboarding-slide-$index'),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: viewport.maxHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 540,
                minHeight: (viewport.maxHeight - 44).clamp(0, double.infinity),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),
                  LayoutBuilder(
                    builder: (context, content) => switch (index) {
                      0 => _gamesContent(content.maxWidth),
                      1 => _friendsContent(content.maxWidth),
                      _ => _tournamentsContent(content.maxWidth),
                    },
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _pageIndicators(),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Center(
                          child: FractionallySizedBox(
                            widthFactor: 0.82,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 320),
                              child: _getStartedButton(index),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF210000),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/Crimson Gold Lightwave Wallpaper.png',
            fit: BoxFit.cover,
            opacity: const AlwaysStoppedAnimation(0.30),
            excludeFromSemantics: true,
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, viewport) => PageView.builder(
                controller: _pageController,
                itemCount: _slideLabels.length,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemBuilder: (context, index) => _slide(index, viewport),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpadeDivider extends StatelessWidget {
  const _SpadeDivider();

  @override
  Widget build(BuildContext context) {
    Widget line(bool reverse) => Flexible(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 90),
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: reverse
                ? const [Color(0xFFFFD454), Color(0x00FFD454)]
                : const [Color(0x00FFD454), Color(0xFFFFD454)],
          ),
        ),
      ),
    );
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          line(false),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: CustomPaint(size: Size(28, 32), painter: _SpadePainter()),
          ),
          line(true),
        ],
      ),
    );
  }
}

class _SpadePainter extends CustomPainter {
  const _SpadePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 28, size.height / 32);
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFF09B), Color(0xFFFFD454), Color(0xFFFFB51B)],
      ).createShader(const Rect.fromLTWH(0, 0, 28, 32));
    final spade = Path()
      ..moveTo(14, 1)
      ..cubicTo(10, 7, 1, 12, 1, 19)
      ..cubicTo(1, 27, 10, 29, 14, 22)
      ..cubicTo(13, 26, 12, 29, 9, 31)
      ..lineTo(19, 31)
      ..cubicTo(16, 29, 15, 26, 14, 22)
      ..cubicTo(18, 29, 27, 27, 27, 19)
      ..cubicTo(27, 12, 18, 7, 14, 1)
      ..close();
    canvas.drawPath(spade, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SpadePainter oldDelegate) => false;
}

class _CrownPainter extends CustomPainter {
  const _CrownPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 68, size.height / 48);
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF8AD), Color(0xFFFFCB20), Color(0xFFF59A00)],
      ).createShader(const Rect.fromLTWH(0, 0, 68, 48));
    final crown = Path()
      ..moveTo(9, 14)
      ..lineTo(22, 27)
      ..lineTo(34, 3)
      ..lineTo(46, 27)
      ..lineTo(59, 14)
      ..lineTo(54, 37)
      ..quadraticBezierTo(34, 32, 14, 37)
      ..close();
    canvas.drawPath(crown, paint);
    for (final point in [
      const Offset(9, 13),
      const Offset(34, 4),
      const Offset(59, 13),
    ]) {
      canvas.drawCircle(point, 4, paint);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(14, 40, 40, 6),
        const Radius.circular(3),
      ),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CrownPainter oldDelegate) => false;
}
