import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../core/utils/page_transitions.dart';
import '../features/onboarding/auto_login_screen.dart';

/// Listens for the invite auto-login deep link and routes to the handoff
/// screen. Expected link shape (see functions/config.js DEEP_LINK_BASE):
///   https://theunieats.com/vendor/onboarding?rid=<id>&t=<secret>&env=<test|live>
/// or the custom scheme unieats-vendor://onboarding?rid=...&t=...&env=...
class DeepLinkService {
  DeepLinkService(this._navigatorKey);

  final GlobalKey<NavigatorState> _navigatorKey;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  Future<void> init() async {
    // Cold start: app launched by tapping the link.
    final initial = await _appLinks.getInitialLink();
    if (initial != null) _handle(initial);
    // Warm start: link tapped while app is running.
    _sub = _appLinks.uriLinkStream.listen(_handle, onError: (_) {});
  }

  void _handle(Uri uri) {
    final rid = uri.queryParameters['rid'];
    final secret = uri.queryParameters['t'];
    if (rid == null || rid.isEmpty || secret == null || secret.isEmpty) return;
    final env = uri.queryParameters['env'] == 'live' ? 'live' : 'test';

    final nav = _navigatorKey.currentState;
    if (nav == null) return;
    nav.push(fadeSlidePage(
      AutoLoginScreen(registrationId: rid, secret: secret, env: env),
    ));
  }

  void dispose() {
    _sub?.cancel();
  }
}
