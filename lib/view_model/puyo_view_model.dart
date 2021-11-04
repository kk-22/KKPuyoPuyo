import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter/src/services/keyboard_key.dart';
import 'package:kk_puyopuyo/model/controlled_puyo.dart';
import 'package:kk_puyopuyo/model/puyo.dart';

class PuyoViewModel {
  static const numberOfRow = 12;
  static const numberOfColumn = 6;
  static const maxSquare = numberOfColumn * numberOfRow;
  static const numberOfNext = 2; // 次ぷよの表示数

  // 左上が(0,0)、第1添え字が列
  final List<List<Puyo>> puyoTable = List<List<Puyo>>.generate(
    numberOfColumn,
    (_) => List<Puyo>.generate(numberOfRow, (_) => Puyo()),
  );

  // 第1要素は現在操作中のぷよ。
  final List<ControlledPuyo> _controlledPuyos = [];

  PuyoViewModel() {
    _clear();
    _movePuyo(false, _controlledPuyos.first);
  }

  Puyo puyoOfIndex(int index) {
    final column = index % numberOfColumn;
    final row = index ~/ numberOfColumn;
    return puyoOf(column, row);
  }

  Puyo puyoOfPoint(Point<int> point) {
    return puyoOf(point.x, point.y);
  }

  Puyo puyoOf(int column, int row) {
    return puyoTable[column][row];
  }

  void _clear() {
    _controlledPuyos.clear();
    for (var i = 0; i < numberOfNext + 1; i++) {
      _controlledPuyos.add(ControlledPuyo());
    }
  }

  void controlPuyo(LogicalKeyboardKey key) {
    final current = _controlledPuyos.first;
    final ControlledPuyo next;
    if (key == LogicalKeyboardKey.keyA) {
      next = ControlledPuyo.moved(
          current, Point(current.mainPoint.x - 1, current.mainPoint.y));
    } else if (key == LogicalKeyboardKey.keyD) {
      next = ControlledPuyo.moved(
          current, Point(current.mainPoint.x + 1, current.mainPoint.y));
    } else if (key == LogicalKeyboardKey.keyS) {
      _freeFallPuyo();
      return;
    } else {
      return;
    }

    if (_canMovePuyoTo(current, next.mainPoint) &&
        _canMovePuyoTo(current, next.subPoint)) {
      _movePuyo(true, next);
    }
  }

  bool _canMovePuyoTo(ControlledPuyo current, Point<int> point) {
    if (current.mainPoint == point || current.subPoint == point) return true;
    if (point.x < 0 || numberOfColumn <= point.x) return false;
    if (point.y < 0 || numberOfRow <= point.y) return false;
    return puyoOfPoint(point).type == PuyoType.none;
  }

  void _movePuyo(bool isReplace, ControlledPuyo next) {
    if (isReplace) {
      final controlled = _controlledPuyos.first;
      puyoOfPoint(controlled.mainPoint).type = PuyoType.none;
      puyoOfPoint(controlled.subPoint).type = PuyoType.none;
      _controlledPuyos.removeAt(0);
      _controlledPuyos.insert(0, next);
    }
    puyoOfPoint(next.mainPoint).type = next.mainType;
    puyoOfPoint(next.subPoint).type = next.subType;
  }

  // 操作していたぷよを固定する
  void _freeFallPuyo() {
    for (var column = 0; column < numberOfColumn; column++) {
      for (var row = numberOfRow - 1; 0 <= row; row--) {
        final currentPuyo = puyoOf(column, row);
        if (currentPuyo.type != PuyoType.none) continue;
        var isAllNone = true;
        for (var i = row - 1; 0 <= i; i--) {
          final topPuyo = puyoOf(column, i);
          if (topPuyo.type == PuyoType.none) continue;
          currentPuyo.type = topPuyo.type;
          topPuyo.type = PuyoType.none;
          isAllNone = false;
          break;
        }
        if (isAllNone) break;
      }
    }

    // 次のぷよを作成
    _controlledPuyos.removeAt(0);
    _controlledPuyos.add(ControlledPuyo());
    _movePuyo(false, _controlledPuyos.first);
  }
}
