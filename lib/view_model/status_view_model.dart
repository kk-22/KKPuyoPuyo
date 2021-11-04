import 'package:flutter/material.dart';

class StatusViewModel with ChangeNotifier {

  var _status = GameStatus.play;

  GameStatus get status => _status;

  set status(value) {
    if (_status == value) return;
    _status = value;
   notifyListeners();
  }
}

enum GameStatus {
  play, chain, pause, lose,
}

extension GameStatusEx on GameStatus {
  String title() {
    switch (this) {
      case GameStatus.play:
        return "プレイ中";
      case GameStatus.chain:
        return "連鎖中";
      case GameStatus.pause:
        return "停止中";
      case GameStatus.lose:
        return "敗北";
    }
  }
}