import 'package:flutter/material.dart';
import './widgets/activity/first.dart';
import './widgets/leftcolumn/textfield.dart';
void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const appTitle = '审计工具';
    return MaterialApp(
      title: appTitle,
      home: Scaffold(
        appBar: AppBar(
          title: const Text(appTitle),
        ),
        body: Center(
          child: FractionallySizedBox(
            widthFactor: 0.7,
            heightFactor: 0.3,
            child: MyCustomForm(),) ),
        // body: Row(children: [Column(children: [FileList()],)],),
      ),
    );
  }
}
