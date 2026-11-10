import 'package:flutter/material.dart';

const rewardGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFFFFE779), Color(0xFFFFC12D), Color(0xFFF29A06)],
  stops: [0, 0.45, 1],
);

class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.child, this.signUp = false});

  final Widget child;
  final bool signUp;

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final theme = Theme.of(context);
    const gold = Color(0xFFFFD25A);
    const cream = Color(0xFFFFF5E7);
    const muted = Color(0xFFD5C4BA);
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );
    final authTheme = theme.copyWith(
      colorScheme: theme.colorScheme.copyWith(
        primary: gold,
        onPrimary: const Color(0xFF261000),
        secondary: gold,
        onSurface: cream,
        onSurfaceVariant: muted,
        error: const Color(0xFFFFB4AB),
      ),
      textTheme: theme.textTheme
          .apply(bodyColor: cream, displayColor: cream)
          .copyWith(
            bodyMedium: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              color: muted,
            ),
            bodyLarge: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 14,
              color: cream,
            ),
            titleMedium: theme.textTheme.titleMedium?.copyWith(
              fontSize: 14,
              color: cream,
            ),
          ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x6B1B0300),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        labelStyle: const TextStyle(fontSize: 14, color: muted),
        floatingLabelStyle: const TextStyle(fontSize: 13, color: gold),
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFAD9387)),
        errorStyle: const TextStyle(fontSize: 12, height: 1.2),
        errorMaxLines: 3,
        prefixIconColor: muted,
        suffixIconColor: muted,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 48,
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
        border: border(const Color(0xFFAC663C)),
        enabledBorder: border(const Color(0xFFAC663C)),
        disabledBorder: border(const Color(0xFF725044)),
        focusedBorder: border(gold, 1.5),
        errorBorder: border(const Color(0xFFFFB4AB)),
        focusedErrorBorder: border(const Color(0xFFFFB4AB), 1.5),
      ),
      iconTheme: const IconThemeData(size: 20, color: muted),
      dividerTheme: const DividerThemeData(color: Color(0x667C442C)),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: gold,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          textStyle: theme.textTheme.labelLarge?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cream,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          side: const BorderSide(color: Color(0xFFAC663C)),
          shape: const StadiumBorder(),
        ),
      ),
    );
    return Theme(
      data: authTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFF1C0200),
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
                builder: (context, constraints) => SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 32).clamp(
                        0,
                        double.infinity,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: 430,
                          minHeight: (constraints.maxHeight - 32).clamp(0, 820),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 24,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _AuthHero(
                              signUp: signUp,
                              keyboardOpen: keyboardOpen,
                              imageHeight:
                                  (constraints.maxHeight *
                                          (signUp ? 0.22 : 0.25))
                                      .clamp(96, 180),
                            ),
                            SizedBox(height: keyboardOpen ? 20 : 26),
                            AutofillGroup(child: child),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthHero extends StatelessWidget {
  const _AuthHero({
    required this.signUp,
    required this.keyboardOpen,
    required this.imageHeight,
  });

  final bool signUp;
  final bool keyboardOpen;
  final double imageHeight;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (!keyboardOpen) ...[
        ExcludeSemantics(
          child: SizedBox(
            height: imageHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 220,
                  height: imageHeight * 0.65,
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      colors: [Color(0x44EF7E15), Color(0x00EF7E15)],
                    ),
                  ),
                ),
                Image.asset(
                  'assets/images/card.png',
                  width: double.infinity,
                  height: imageHeight,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
      Text(
        signUp ? 'Create Account' : 'Welcome Back!',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: const Color(0xFFFFF0D5),
          fontSize: keyboardOpen ? 25 : 30,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          height: 1.1,
          shadows: const [Shadow(color: Color(0x88DA812A), blurRadius: 10)],
        ),
      ),
      if (!keyboardOpen) ...[
        const SizedBox(height: 8),
        Text(
          signUp
              ? 'Join now and start playing your favorite games.'
              : 'Sign in to continue your gaming journey.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFE2D3C9),
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    ],
  );
}

class RewardButton extends StatelessWidget {
  const RewardButton({super.key, required this.onPressed, required this.child});

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: rewardGradient,
      borderRadius: BorderRadius.circular(100),
      border: Border.all(color: const Color(0xFFFFDF80)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x44FF8B14),
          blurRadius: 18,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.transparent,
        disabledBackgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        foregroundColor: const Color(0xFF251000),
        disabledForegroundColor: const Color(0xFF684515),
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: const StadiumBorder(),
        textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
      child: child,
    ),
  );
}
