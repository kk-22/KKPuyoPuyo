import 'package:flutter/material.dart';
import 'package:kk_puyopuyo/view/square_view.dart';
import 'package:kk_puyopuyo/view_model/puyo_view_model.dart';
import 'package:provider/provider.dart';
import 'package:provider/src/provider.dart';

class MainField extends StatelessWidget {
  const MainField({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final puyoModel = context.read<PuyoViewModel>();
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.height *
            PuyoViewModel.numberOfColumn /
            PuyoViewModel.numberOfRow,
        child: GridView.count(
          crossAxisCount: PuyoViewModel.numberOfColumn,
          childAspectRatio: 1.0,
          children: List.generate(PuyoViewModel.maxSquare, (index) {
            return ChangeNotifierProvider.value(
              value: puyoModel.puyoOfIndex(index),
              child: const SquareView(),
            );
          }),
        ),
      ),
    );
  }
}
