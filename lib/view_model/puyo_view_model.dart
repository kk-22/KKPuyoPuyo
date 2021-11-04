import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kk_puyopuyo/model/controlled_puyo.dart';
import 'package:kk_puyopuyo/model/puyo.dart';
import 'package:kk_puyopuyo/view_model/timer_view_model.dart';
import 'package:provider/provider.dart';

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
  late TimerViewModel _timerModel;

  void init(BuildContext context) {
    _timerModel = context.read<TimerViewModel>();
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
    for (var column = 0; column < numberOfColumn; column++) {
      for (var row = numberOfRow - 1; 0 <= row; row--) {
        puyoOf(column, row).type = PuyoType.none;
      }
    }
    _controlledPuyos.clear();
    for (var i = 0; i < numberOfNext + 1; i++) {
      _controlledPuyos.add(ControlledPuyo());
    }
    _movePuyo(false, _controlledPuyos.first);

    _timerModel.reset();
  }

  void timeHasPassed() {
    final current = _controlledPuyos.first;
    final next = ControlledPuyo.moved(current,
        nextPoint: Point(current.mainPoint.x, current.mainPoint.y + 1));
    if (_canMovePuyoTo(current, next.mainPoint) &&
        _canMovePuyoTo(current, next.subPoint)) {
      // 一段下げる
      _movePuyo(true, next);
      return;
    }
    _freeFallPuyo();
  }

  void controlPuyo(LogicalKeyboardKey key) {
    final current = _controlledPuyos.first;
    if (key == LogicalKeyboardKey.keyS) {
      _timerModel.reset();
      _freeFallPuyo();
      return;
    } else if (key == LogicalKeyboardKey.keyA ||
        key == LogicalKeyboardKey.keyD) {
      final x = current.mainPoint.x + (key == LogicalKeyboardKey.keyA ? -1 : 1);
      final next = ControlledPuyo.moved(current,
          nextPoint: Point(x, current.mainPoint.y));
      if (_canMovePuyoTo(current, next.mainPoint) &&
          _canMovePuyoTo(current, next.subPoint)) {
        _movePuyo(true, next);
      }
    } else if (key == LogicalKeyboardKey.keyE ||
        key == LogicalKeyboardKey.keyQ) {
      final turnToRight = key == LogicalKeyboardKey.keyE;
      final turned = current.subPosition.turned(turnToRight);
      var next = ControlledPuyo.moved(current, nextPosition: turned);
      if (!_canMovePuyoTo(current, next.subPoint)) {
        if (current.subPosition.isVertical()) {
          // X軸をずらして回転
          final x = current.mainPoint.x +
              (current.subPosition.isPushedToRight(turnToRight) ? 1 : -1);
          next = ControlledPuyo.moved(current,
              nextPoint: Point(x, current.mainPoint.y), nextPosition: turned);
          if (!_canMovePuyoTo(current, next.mainPoint)) {
            // 左右の入れ替えのみ行う
            final upside = current.subPosition.upsideDown();
            next = ControlledPuyo.moved(current,
                nextPoint: current.subPoint, nextPosition: upside);
          }
        } else {
          // 1段持ち上げる
          final y = current.mainPoint.y + 1;
          next = ControlledPuyo.moved(current,
              nextPoint: Point(current.mainPoint.x, y), nextPosition: turned);
        }
      }
      _movePuyo(true, next);
    } else if (key == LogicalKeyboardKey.space) {
      // タイマー操作
      if (_timerModel.isStarting()) {
        _timerModel.stopTimerIfNeeded();
      } else {
        _timerModel.startIfNeeded();
      }
    } else if (key == LogicalKeyboardKey.keyC) {
      _clear();
    } else {
      return;
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
