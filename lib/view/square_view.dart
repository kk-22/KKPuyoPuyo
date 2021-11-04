import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kk_puyopuyo/model/puyo.dart';
import 'package:provider/src/provider.dart';

class SquareView extends StatelessWidget {
  const SquareView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final puyo = context.read<Puyo>();
    return Container(
      decoration: BoxDecoration(
        color: puyo.squareColor,
        border: Border.all(color: Colors.black, width: 1),
      ),
    );
  }
}
