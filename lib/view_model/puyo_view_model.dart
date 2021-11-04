import 'package:kk_puyopuyo/model/puyo.dart';

class PuyoViewModel {
  static const numberOfRow = 12;
  static const numberOfColumn = 6;
  static const maxSquare = numberOfColumn * numberOfRow;

  // 左下が(0,0)、第1添え字が列
  final List<List<Puyo>> puyoTable = List<List<Puyo>>.generate(
    numberOfRow,
    (_) => List<Puyo>.generate(numberOfColumn, (_) => Puyo()),
  );

  Puyo puyoOfIndex(int index) {
    final column = index ~/ numberOfColumn;
    final row = index % numberOfColumn;
    return puyoTable[column][row];
  }
}
