import 'package:flutter/material.dart';
class FileList extends StatelessWidget {
  const FileList ({super.key});
  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
          TextField(
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: '输入路径',
            ),
          ),
        // ListView()
      ],
    );
  }
}