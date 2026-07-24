import 'dart:async';
import 'package:flutter/widgets.dart';
import '../api/healthcare_api.dart';

class AppUsageTracker with WidgetsBindingObserver {
  static final AppUsageTracker instance = AppUsageTracker._internal();

  AppUsageTracker._internal();

  Timer? _timer;
  int _unsyncedSeconds = 0;
  int _liveTotalSeconds = 0;
  bool _isTracking = false;

  final ValueNotifier<int> totalUsageNotifier = ValueNotifier<int>(0);

  void initialize() {
    WidgetsBinding.instance.addObserver(this);
    startTracking();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    stopTracking();
  }

  String? _activeChildId;

  void syncWithChildProfile(int totalSeconds, {String? childId}) {
    final currentChildId = childId ?? HealthcareApi.instance.currentChild?.id;
    if (currentChildId != null && currentChildId != _activeChildId) {
      _activeChildId = currentChildId;
      _liveTotalSeconds = totalSeconds;
      _unsyncedSeconds = 0;
      totalUsageNotifier.value = _liveTotalSeconds;
      return;
    }
    if (totalSeconds > _liveTotalSeconds) {
      _liveTotalSeconds = totalSeconds;
      totalUsageNotifier.value = _liveTotalSeconds;
    }
  }

  int get currentTotalUsageSeconds => _liveTotalSeconds;

  void startTracking() {
    if (_isTracking) return;
    _isTracking = true;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _unsyncedSeconds++;
      _liveTotalSeconds++;
      totalUsageNotifier.value = _liveTotalSeconds;

      // Periodically sync every 30 seconds
      if (_unsyncedSeconds >= 30) {
        _syncToBackend();
      }
    });
  }

  void stopTracking() {
    _isTracking = false;
    _timer?.cancel();
    _timer = null;
    _syncToBackend();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      startTracking();
    } else {
      stopTracking();
    }
  }

  Future<void> _syncToBackend() async {
    final secondsToSync = _unsyncedSeconds;
    if (secondsToSync <= 0) return;

    final childId = HealthcareApi.instance.currentChild?.id;
    if (childId == null || childId.isEmpty) return;

    _unsyncedSeconds -= secondsToSync;
    try {
      final updatedTotal = await HealthcareApi.instance.children.recordAppUsage(childId, secondsToSync);
      if (updatedTotal > 0) {
        _liveTotalSeconds = updatedTotal + _unsyncedSeconds;
        totalUsageNotifier.value = _liveTotalSeconds;
      }
    } catch (_) {
      // If sync fails, restore unsynced seconds for next attempt
      _unsyncedSeconds += secondsToSync;
    }
  }

  /// Formats total seconds into friendly Persian text
  /// Example: 663 seconds -> "۱۱ دقیقه و ۳ ثانیه" or "11 دقیقه و 3 ثانیه"
  static String formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return '۰ ثانیه';

    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final parts = <String>[];

    if (hours > 0) {
      parts.add('${toPersianDigits(hours)} ساعت');
    }
    if (minutes > 0) {
      parts.add('${toPersianDigits(minutes)} دقیقه');
    }
    if (seconds > 0 || parts.isEmpty) {
      parts.add('${toPersianDigits(seconds)} ثانیه');
    }

    return parts.join(' و ');
  }

  static String toPersianDigits(int number) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

    String str = number.toString();
    for (int i = 0; i < english.length; i++) {
      str = str.replaceAll(english[i], persian[i]);
    }
    return str;
  }
}
