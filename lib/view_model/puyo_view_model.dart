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
  final _puyoTable = List<List<Puyo>>.generate(
    numberOfColumn,
    (_) => List<Puyo>.generate(numberOfRow, (_) => Puyo()),
  );
  final _nextPuyos = List<Puyo>.generate(
    numberOfNext * 2,
    (_) => Puyo(),
  );

  // 第1要素は現在操作中のぷよ。第2要素以降は画面右上に表示する
  final List<ControlledPuyo> _controlledPuyos = [];
  late TimerViewModel _timerModel;

  void init(BuildContext context) {
    _timerModel = context.read<TimerViewModel>();
    _clear();
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
    return _puyoTable[column][row];
  }

  Puyo nextPuyo(int index) {
    return _nextPuyos[index];
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
    _updateNextPuyo();

    _timerModel.reset();
  }

  void timeHasPassed() {
    final current = _controlledPuyos.first;
    final next = ControlledPuyo.moved(current,
        nextPoint: Point(current.mainPoint.x, current.mainPoint.y + 1));
    if (_canMovePuyoTo(current, next.mainPoint) &&
        _canMovePuyoTo(current, next.subPoint)) {
      // 一段下げる
      _movePuyo(next);
      return;
    }
    _timerModel.stopTimerIfNeeded();
    _freeFallPuyo();
  }

  void controlPuyo(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.space) {
      // タイマー操作
      if (_timerModel.isStarting()) {
        _timerModel.stopTimerIfNeeded();
      } else {
        _timerModel.startIfNeeded();
      }
      return;
    }
    if (!_timerModel.isStarting()) return;

    final current = _controlledPuyos.first;
    if (key == LogicalKeyboardKey.keyS) {
      _timerModel.stopTimerIfNeeded();
      _freeFallPuyo();
    } else if (key == LogicalKeyboardKey.keyA ||
        key == LogicalKeyboardKey.keyD) {
      final x = current.mainPoint.x + (key == LogicalKeyboardKey.keyA ? -1 : 1);
      final next = ControlledPuyo.moved(current,
          nextPoint: Point(x, current.mainPoint.y));
      if (_canMovePuyoTo(current, next.mainPoint) &&
          _canMovePuyoTo(current, next.subPoint)) {
        _movePuyo(next);
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
      _movePuyo(next);
    } else if (key == LogicalKeyboardKey.keyC) {
      _clear();
    }
  }

  bool _canMovePuyoTo(ControlledPuyo current, Point<int> point) {
    if (current.mainPoint == point || current.subPoint == point) return true;
    if (!_isIndexExist(point.x, point.y)) return false;
    return puyoOfPoint(point).type == PuyoType.none;
  }

  void _movePuyo(ControlledPuyo next) {
    final controlled = _controlledPuyos.first;
    puyoOfPoint(controlled.mainPoint).type = PuyoType.none;
    puyoOfPoint(controlled.subPoint).type = PuyoType.none;
    _controlledPuyos.removeAt(0);
    _controlledPuyos.insert(0, next);

    puyoOfPoint(next.mainPoint).type = next.mainType;
    puyoOfPoint(next.subPoint).type = next.subType;
  }

  void _updateNextPuyo() {
    final control = _controlledPuyos[0];
    puyoOfPoint(control.mainPoint).type = control.mainType;
    puyoOfPoint(control.subPoint).type = control.subType;

    for (var i = 0; i < numberOfNext; i++) {
      final control = _controlledPuyos[i + 1];
      nextPuyo(i * 2).type = control.subType;
      nextPuyo(i * 2 + 1).type = control.mainType;
    }
  }

  // 操作していたぷよを固定する
  Future<void> _freeFallPuyo() async {
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

    if (await _deleteConnectedPuyos()) {
      _freeFallPuyo();
    } else {
      // 次のぷよを作成
      _controlledPuyos.removeAt(0);
      _controlledPuyos.add(ControlledPuyo());
      _updateNextPuyo();
      _timerModel.startIfNeeded();
    }
  }

  // 1つでも削除したら true を返す
  Future<bool> _deleteConnectedPuyos() async {
    final resultTable = List<List<bool>>.generate(
      numberOfColumn,
      (_) => List<bool>.filled(numberOfRow, false),
    );
    final List<Point<int>> deletePoints = [];
    for (var column = 0; column < numberOfColumn; column++) {
      for (var row = numberOfRow - 1; 0 <= row; row--) {
        List<Point<int>> checkedTable = [];
        _searchConnectedPuyo(column, row, null, checkedTable, resultTable);
        if (4 <= checkedTable.length) {
          deletePoints.addAll(checkedTable);
        }
      }
    }
    if (deletePoints.isEmpty) return false;

    await Future.delayed(const Duration(milliseconds: 500));
    for (var point in deletePoints) {
      puyoOfPoint(point).type = PuyoType.none;
    }
    return true;
  }

  void _searchConnectedPuyo(int column, int row, PuyoType? prevType,
      List<Point<int>> checkedTable, List<List<bool>> resultTable) {
    if (!_isIndexExist(column, row)) return;
    if (resultTable[column][row]) return;

    final puyo = puyoOf(column, row);
    if (prevType != null) {
      if (prevType != puyo.type) return;
    } else {
      if (puyo.type == PuyoType.none) return;
    }
    // 逆流防止のため先にチェック済みフラグを立てる
    resultTable[column][row] = true;
    checkedTable.add(Point(column, row));
    _searchConnectedPuyo(column + 1, row, puyo.type, checkedTable, resultTable);
    _searchConnectedPuyo(column - 1, row, puyo.type, checkedTable, resultTable);
    _searchConnectedPuyo(column, row + 1, puyo.type, checkedTable, resultTable);
    _searchConnectedPuyo(column, row - 1, puyo.type, checkedTable, resultTable);
  }

  bool _isIndexExist(int column, int row) {
    if (column < 0 || numberOfColumn <= column) return false;
    if (row < 0 || numberOfRow <= row) return false;
    return true;
  }
}
