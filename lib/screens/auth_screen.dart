/// Auth screen: first-launch password setup and returning-user login.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../state/controllers.dart';
import '../widgets/smooth_color.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({
    super.key,
    required this.titleKey,
    required this.titleDelta,
  });

  /// Measuring key for the wordmark (used by the root to compute the morph).
  final GlobalKey titleKey;

  /// Where the wordmark starts its morph, or null when none is needed.
  final Offset? titleDelta;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _morph;

  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  final TextEditingController _login = TextEditingController();

  final FocusNode _firstFieldFocus = FocusNode();
  Timer? _loginDebounce;
  bool _submitted = false;
  bool _githubHovered = false;

  @override
  void initState() {
    super.initState();
    _morph = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    if (!ref.read(authControllerProvider).hasPassword) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _firstFieldFocus.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(covariant AuthScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.titleDelta != null && !_morph.isAnimating && _morph.value == 0) {
      _morph.forward();
    }
  }

  @override
  void dispose() {
    _loginDebounce?.cancel();
    _morph.dispose();
    _password.dispose();
    _confirm.dispose();
    _login.dispose();
    _firstFieldFocus.dispose();
    super.dispose();
  }

  void _submitSetup() {
    if (_submitted) return;
    _submitted = true;
    Future(() async {
      await ref
          .read(authControllerProvider.notifier)
          .submitSetup(_password.text, _confirm.text);
      if (mounted) _submitted = false;
    });
  }

  void _onLoginChanged(String value) {
    _loginDebounce?.cancel();
    _loginDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      ref.read(authControllerProvider.notifier).onLoginChanged(value);
    });
  }

  Future<void> _openGitHub() async {
    final uri = Uri.parse(githubUrl);
    // The link is user-initiated; the app itself never touches the network.
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final palette = Palette(Theme.of(context).brightness == Brightness.dark);
    final isSetup = !ref.watch(authControllerProvider).hasPassword;

    return ColoredBox(
      color: palette.background,
      child: Center(
        child: SingleChildScrollView(
          child: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTitle(palette),
                const SizedBox(height: 8),
                Text(
                  isSetup
                      ? Messages.welcomeSubtitle
                      : Messages.welcomeBackSubtitle,
                  textAlign: TextAlign.center,
                  style: Styles.ui(
                    size: 14,
                    color: palette.mutedText,
                    style: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 32),
                if (isSetup) _buildSetupForm(palette) else _buildLoginForm(),
                const SizedBox(height: 24),
                _buildGitHubButton(palette),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The wordmark, eased from the splash's position to rest.
  Widget _buildTitle(Palette palette) {
    return AnimatedBuilder(
      animation: _morph,
      builder: (context, child) {
        final delta = widget.titleDelta ?? Offset.zero;
        final progress = Curves.easeInOutCubic.transform(_morph.value);
        return Transform.translate(
          offset: delta * (1 - progress),
          child: child,
        );
      },
      child: Text(
        'CalenLog',
        key: widget.titleKey,
        textAlign: TextAlign.center,
        style: Styles.brand(size: 36, color: palette.text),
      ),
    );
  }

  Widget _buildSetupForm(Palette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _password,
          focusNode: _firstFieldFocus,
          obscureText: true,
          autofocus: false,
          maxLength: 64,
          style: Styles.ui(size: 14, color: palette.text),
          onSubmitted: (_) => _submitSetup(),
          decoration: InputDecoration(
            hintText: Messages.setPasswordHint,
            hintStyle: Styles.ui(size: 14, color: palette.mutedText),
            counterText: '',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirm,
          obscureText: true,
          maxLength: 64,
          style: Styles.ui(size: 14, color: palette.text),
          onSubmitted: (_) => _submitSetup(),
          decoration: InputDecoration(
            hintText: Messages.confirmPasswordHint,
            hintStyle: Styles.ui(size: 14, color: palette.mutedText),
            counterText: '',
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _submitSetup,
          style: ElevatedButton.styleFrom(
            backgroundColor: palette.buttonBg,
            foregroundColor: palette.buttonFg,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: Text(
            Messages.letsGo,
            style: Styles.ui(size: 14, weight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  /// Returning user: a single field with no submit button. Verification runs
  /// 300 ms after typing pauses; success moves straight into the app.
  Widget _buildLoginForm() {
    return TextField(
      controller: _login,
      autofocus: true,
      obscureText: true,
      maxLength: 64,
      onChanged: _onLoginChanged,
      decoration: const InputDecoration(
        hintText: Messages.loginHint,
        counterText: '',
      ),
    );
  }

  Widget _buildGitHubButton(Palette palette) {
    return Center(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _githubHovered = true),
        onExit: (_) => setState(() => _githubHovered = false),
        child: Tooltip(
          message: Messages.githubLinkLabel,
          child: InkWell(
            onTap: _openGitHub,
            borderRadius: BorderRadius.circular(4),
            // matches the SmoothColor fade below so highlight and tint land together
            hoverDuration: kHoverFade,
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: SmoothColor(
                color: _githubHovered
                    ? palette.hoverShade(palette.mutedText)
                    : palette.mutedText,
                builder: (context, color) => Image.asset(
                  'assets/images/github_mark.png',
                  width: 22,
                  height: 22,
                  color: color,
                  colorBlendMode: BlendMode.srcIn,
                  errorBuilder: (_, _, _) =>
                      Icon(Icons.code, size: 18, color: color),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
