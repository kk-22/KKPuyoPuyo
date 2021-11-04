import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kk_puyopuyo/view/main_field.dart';
import 'package:kk_puyopuyo/view_model/puyo_view_model.dart';
import 'package:kk_puyopuyo/view_model/timer_view_model.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PuyoPuyo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MultiProvider(
        providers: [
          Provider<PuyoViewModel>(create: (_) => PuyoViewModel()),
          Provider<TimerViewModel>(create: (_) => TimerViewModel()),
        ],
        builder: (context, child) {
          final focusNode = FocusNode();
          focusNode.requestFocus();
          final puyoModel = context.read<PuyoViewModel>();
          puyoModel.init(context);
          context.read<TimerViewModel>().init(context);
          return RawKeyboardListener(
            focusNode: focusNode,
            onKey: (event) {
              if (event is RawKeyDownEvent) {
                puyoModel.controlPuyo(event.logicalKey);
              }
            },
            child: const Center(child: MainField()),
          );
        },
      ),
    );
  }
}
