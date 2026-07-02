import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../services/firestore_order_service.dart' show AppEnv;

/// Light onboarding funnel logging so the rep pipeline / ops can see drop-off:
/// registration_created, details_confirmed, password_set, documents_submitted,
/// approved, activated (first full-app open). Fire-and-forget — analytics must
/// never block or break the flow.
class OnboardingAnalytics {
  OnboardingAnalytics._();

  static void log(String event, {Map<String, dynamic>? params}) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    FirebaseFirestore.instance.collection(AppEnv.col('onboarding_events')).add({
      'event': event,
      'uid': uid,
      'params': params ?? {},
      'at': FieldValue.serverTimestamp(),
    }).catchError((e) {
      debugPrint('onboarding analytics "$event" failed: $e');
      return FirebaseFirestore.instance.collection('_noop').doc('_noop');
    });
  }
}
