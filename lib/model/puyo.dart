import 'package:flutter/material.dart';

class Puyo with ChangeNotifier {
  var _type = PuyoType.none;

  get type => _type;

  get squareColor {
    switch (_type) {
      case PuyoType.none:
        return Colors.transparent;
      case PuyoType.red:
        return Colors.red;
      case PuyoType.green:
        return Colors.green;
      case PuyoType.blue:
        return Colors.blue;
      case PuyoType.yellow:
        return Colors.yellow;
    }
  }

  set type(value) {
    _type = value;
    notifyListeners();
  }
}

enum PuyoType {
  red,
  green,
  blue,
  yellow,
  none,
}
