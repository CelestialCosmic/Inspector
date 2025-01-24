import 'package:flutter/material.dart';
import '../storage/storage.dart';
import '../leftcolumn/fileview.dart';

class MyCustomForm extends StatefulWidget {
  const MyCustomForm({super.key});
  @override
  MyCustomFormState createState() {
    return MyCustomFormState();
  }
}

class MyCustomFormState extends State<MyCustomForm> {
  final textController = TextEditingController();
  final storage = SharedPref();
  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: textController,
          ),
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: AbsorbPointer(
                    absorbing: false,
                    child: ElevatedButton(
                      onPressed: () {
                          String dir = textController.text;
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const DirectoryTree()));
                          if (dir == "") {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('路径不可为空')),
                            );
                            return;
                          }
                          storage.save("dir", dir);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('正在获取 $dir ，请稍后')),
                          );
                          print(dir);
                        
                      },
                      child: const Text('提交路径'),
                    )),
              )),
        ]);
  }
}

