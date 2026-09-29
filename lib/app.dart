/// Root widget: theming, screen flow and the splash/auth title morph.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'state/controllers.dart';
import 'widgets/error_banner.dart';

class CalenLogApp extends ConsumerStatefulWidget {
  const CalenLogApp({super.key});

  @override
  ConsumerState<CalenLogApp> createState() => _CalenLogAppState();
}

class _CalenLogAppState extends ConsumerState<CalenLogApp> {
  final GlobalKey _authTitleKey = GlobalKey();

  /// Delta between the two wordmarks, or null until the morph starts.
  Offset? _titleDelta;

  bool _splashMounted = true;

  @override
  Widget build(BuildContext context) {
    // A data reset returns to the splash: remount it and clear the delta.
    ref.listen(stageProvider, (previous, next) {
      if (next == AppStage.splash && !_splashMounted) {
        setState(() {
          _splashMounted = true;
          _titleDelta = null;
        });
      }
    });

    final dark = ref.watch(appDataProvider.select((data) => data.darkMode));
    final stage = ref.watch(stageProvider);
    final banner = ref.watch(errorBannerProvider);

    return MaterialApp(
      title: 'CalenLog',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(const Palette(false)),
      darkTheme: buildTheme(const Palette(true)),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 700),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _buildStage(stage),
            ),

            // Splash overlay sits on top and fades out once the morph starts.
            if (_splashMounted)
              AnimatedOpacity(
                opacity: _titleDelta == null ? 1 : 0,
                duration: const Duration(milliseconds: 500),
                onEnd: () {
                  if (mounted) setState(() => _splashMounted = false);
                },
                child: IgnorePointer(
                  child: SplashScreen(
                    key: const ValueKey<String>('splash'),
                    authTitleKey: _authTitleKey,
                    onMorph: _startMorph,
                  ),
                ),
              ),

            if (banner != null) ErrorBannerView(message: banner),
          ],
        ),
      ),
    );
  }

  Widget _buildStage(AppStage stage) {
    switch (stage) {
      case AppStage.splash:
      case AppStage.auth:
        return AuthScreen(
          key: const ValueKey<String>('auth'),
          titleKey: _authTitleKey,
          titleDelta: _titleDelta,
        );
      case AppStage.home:
        return const HomeScreen(key: ValueKey<String>('home'));
    }
  }

  void _startMorph(Offset delta) {
    if (!mounted || _titleDelta != null) return;
    setState(() => _titleDelta = delta);
    ref.read(stageProvider.notifier).show(AppStage.auth);
  }
}
