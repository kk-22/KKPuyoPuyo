import 'package:flutter/material.dart';
import 'package:kk_puyopuyo/view/square_view.dart';
import 'package:kk_puyopuyo/view_model/puyo_view_model.dart';
import 'package:kk_puyopuyo/view_model/status_view_model.dart';
import 'package:provider/provider.dart';

class MainField extends StatelessWidget {
  const MainField({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final puyoModel = context.read<PuyoViewModel>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
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
        Column(
          children: [
            Row(
              children: List.generate(PuyoViewModel.numberOfNext, (nextIndex) {
                return Padding(
                  padding: const EdgeInsets.only(top: 10, left: 10),
                  child: Column(
                      children: List.generate(2, (index) {
                    return ChangeNotifierProvider.value(
                      value: puyoModel.nextPuyo(nextIndex * 2 + index),
                      child: const SizedBox(
                          width: 50, height: 50, child: SquareView()),
                    );
                  })),
                );
              }),
            ),
            Consumer<StatusViewModel>(builder: (context, statusModel, child) {
              return Text(
                statusModel.status.title(),
                style: const TextStyle(color: Colors.cyan, fontSize: 30),
              );
            }),
          ],
        ),
      ],
    );
  }
}
