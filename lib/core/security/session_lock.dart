import 'dart:async';
import 'package:flutter/material.dart';
import 'key_custody.dart';

class SessionLockManager {
  final KeyCustodyService _keyCustody;
  final Duration _timeout;
  final VoidCallback _onLocked;
  Timer? _timer;
  
  SessionLockManager({
    required KeyCustodyService keyCustody,
    Duration timeout = const Duration(minutes: 5),
    required VoidCallback onLocked,
  })  : _keyCustody = keyCustody,
        _timeout = timeout,
        _onLocked = onLocked;

  /// Resets the inactivity timer to prevent auto-lock.
  void activityDetected() {
    _timer?.cancel();
    if (!_keyCustody.isUnlocked) return;
    
    _timer = Timer(_timeout, () {
      _keyCustody.lockVault();
      _onLocked();
    });
  }

  /// Cancels the running timer.
  void dispose() {
    _timer?.cancel();
  }
}

/// A wrapper widget that listens to pointer interactions at the root level.
class SessionLockGate extends StatefulWidget {
  final Widget child;
  final KeyCustodyService keyCustody;
  final VoidCallback onLocked;
  final Duration timeout;

  const SessionLockGate({
    required this.child,
    required this.keyCustody,
    required this.onLocked,
    this.timeout = const Duration(minutes: 5),
    super.key,
  });

  @override
  State<SessionLockGate> createState() => _SessionLockGateState();
}

class _SessionLockGateState extends State<SessionLockGate> {
  late SessionLockManager _lockManager;

  @override
  void initState() {
    super.initState();
    _lockManager = SessionLockManager(
      keyCustody: widget.keyCustody,
      timeout: widget.timeout,
      onLocked: widget.onLocked,
    );
    _lockManager.activityDetected();
  }

  @override
  void dispose() {
    _lockManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _lockManager.activityDetected(),
      onPointerMove: (_) => _lockManager.activityDetected(),
      child: widget.child,
    );
  }
}
