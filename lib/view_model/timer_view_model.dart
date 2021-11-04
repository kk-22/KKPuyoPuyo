import 'dart:async';

import 'package:kk_puyopuyo/view_model/puyo_view_model.dart';

class TimerViewModel {
  late PuyoViewModel _puyoModel;
  Timer? _timer;

  void init(PuyoViewModel puyoModel) {
    _puyoModel = puyoModel;
    startIfNeeded();
  }

  bool isStarting() => _timer != null;

  void startIfNeeded() {
    if (isStarting()) return;

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer timer) => _puyoModel.timeHasPassed(),
    );
  }

  void stopTimerIfNeeded() {
    if (isStarting()) {
      _timer?.cancel();
      _timer = null;
    }
  }

  // タイマーのカウントをやり直す
  void reset() {
    stopTimerIfNeeded();
    startIfNeeded();
  }
}
