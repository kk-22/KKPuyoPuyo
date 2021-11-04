import 'dart:math';

import 'package:kk_puyopuyo/model/puyo.dart';
import 'package:kk_puyopuyo/view_model/puyo_view_model.dart';

// 操作対象のぷよ
class MovingPuyo {
  late final PuyoType _mainType; // 回転時に中心点となる方
  late final PuyoType _subType; // 回転時に大きく動く方
  late final Point<int> _mainPoint;
  late final SubPosition _subPosition;

  MovingPuyo() {
    _mainType = randomType();
    _subType = randomType();
    _mainPoint = const Point(PuyoViewModel.numberOfColumn ~/ 2 - 1, 1);
    _subPosition = SubPosition.top;
  }

  MovingPuyo.moved(MovingPuyo old,
      [Point<int>? nextPoint, SubPosition? nextPosition]) {
    _mainType = old.mainType;
    _subType = old.subType;
    _mainPoint = nextPoint ?? old._mainPoint;
    _subPosition = nextPosition ?? old._subPosition;
  }

  PuyoType randomType() {
    final index = Random().nextInt(PuyoType.values.length - 1);
    return PuyoType.values[index];
  }

  PuyoType get mainType => _mainType;

  PuyoType get subType => _subType;

  get mainPoint => _mainPoint;

  Point<int> get subPoint {
    switch (_subPosition) {
      case SubPosition.top:
        return Point(_mainPoint.x, _mainPoint.y - 1);
      case SubPosition.right:
        return Point(_mainPoint.x + 1, _mainPoint.y);
      case SubPosition.bottom:
        return Point(_mainPoint.x, _mainPoint.y + 1);
      case SubPosition.left:
        return Point(_mainPoint.x - 1, _mainPoint.y);
    }
  }
}

enum SubPosition {
  top,
  right,
  bottom,
  left,
}