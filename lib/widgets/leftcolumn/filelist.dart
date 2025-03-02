import 'dart:io';
import 'package:flutter/material.dart';
import './fileviewer/image.dart';
import './fileviewer/pdf.dart';
import './fileviewer/office.dart';

class FileExplorer extends StatefulWidget {
  @override
  State<FileExplorer> createState() => _FileExplorerState();
  final String path;
  const FileExplorer({super.key, required this.path});
}

class _FileExplorerState extends State<FileExplorer> {
  Directory? currentDirectory;
  List<FileSystemEntity> files = [];
  List<Directory> previousDirectories = [];
  String? selectedFile;
  bool isFileSwitch = false;

  @override
  void initState() {
    super.initState();
    _initDirectory(widget.path);
  }

  Future<void> _initDirectory(String path) async {
    Directory directory = Directory(path);
    setState(() {
      currentDirectory = directory;
      _listFiles(directory);
    });
  }

  int _listFiles(Directory directory) {
    try {
      final entities = directory.listSync();
      setState(() {
        files = entities;
      });
      return 1;
    } on PathAccessException {
      return 0;
    } on PathNotFoundException {
      return 2;
    }
  }

  void navigateToFolder(Directory folder) {
    int status = _listFiles(folder);
    if (status != 0) {
      setState(() {
        previousDirectories.add(currentDirectory!);
        currentDirectory = folder;
        isFileSwitch = false;
      });
    }
  }

  void goBack() {
    if (previousDirectories.isNotEmpty) {
      setState(() {
        currentDirectory = previousDirectories.removeLast();
        _listFiles(currentDirectory!);
        isFileSwitch = false;
      });
    }
  }

  void selectFile(String path) {
    setState(() {
      selectedFile = path;
      isFileSwitch = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<String> list = widget.path.split('\\');
    return Scaffold(
      body: Row(
        children: [
          Expanded(
              flex: 1,
              child: FileListView(
                currentDirectory: currentDirectory,
                files: files,
                previousDirectories: previousDirectories,
                onNavigateToFolder: navigateToFolder,
                onGoBack: goBack,
                onSelectFile: selectFile,
                appBarTitle:
                    list.last == "" ? list[list.length - 2] : list.last,
              )),
          Expanded(
              flex: 3,
              child: Window(
                selectedFile: selectedFile,
                isFileSwitch: isFileSwitch,
              )),
          const Expanded(
            flex: 1,
            child: Text("data2"),
          )
        ],
      ),
    );
  }
}

class FileListView extends StatelessWidget {
  final Directory? currentDirectory;
  final List<FileSystemEntity> files;
  final List<Directory> previousDirectories;
  final Function(Directory) onNavigateToFolder;
  final Function() onGoBack;
  final Function(String) onSelectFile;
  final String appBarTitle;

  const FileListView({
    super.key,
    required this.currentDirectory,
    required this.files,
    required this.previousDirectories,
    required this.onNavigateToFolder,
    required this.onGoBack,
    required this.onSelectFile,
    required this.appBarTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        leading: previousDirectories.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onGoBack,
              )
            : null,
      ),
      body: ListView.builder(
        itemCount: files.length,
        itemBuilder: (context, index) {
          final entity = files[index];
          final isFolder = entity is Directory;
          return ListTile(
            leading: isFolder
                ? const Icon(Icons.folder)
                : const Icon(Icons.insert_drive_file),
            title: Text(entity.path.split('\\').last),
            onTap: isFolder
                ? () {
                    onNavigateToFolder(entity);
                  }
                : () {
                    onSelectFile(entity.path);
                  },
          );
        },
      ),
    );
  }
}

class Window extends StatelessWidget {
  final String? selectedFile;
  final bool isFileSwitch;

  const Window(
      {super.key, required this.selectedFile, required this.isFileSwitch});

  @override
  Widget build(BuildContext context) {
    if (selectedFile == null) {
      return const Center(
        child: Text("未选择文件"),
      );
    } else if (isFileSwitch) {
      return FutureBuilder(
        future: _loadFileViewer(selectedFile!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text("加载文件时出错:\n${snapshot.error}"),
            );
          } else {
            return snapshot.data as Widget;
          }
        },
      );
    } else {
      return _buildFileViewer(selectedFile!);
    }
  }

  Widget _buildFileViewer(String selectedFile) {
    if (selectedFile.endsWith("jpg") ||
        selectedFile.endsWith("png") ||
        selectedFile.endsWith("jpeg") ||
        selectedFile.endsWith("webp")) {
      return ImageViewer(
        selectedFile: selectedFile,
      );
    } else if (selectedFile.endsWith("pdf")) {
      return PdfViewer(selectedFile: selectedFile);
    } else if (selectedFile.endsWith("docx") ||
        selectedFile.endsWith("xlsx") ||
        selectedFile.endsWith("pptx")) {
      return OfficeViewer(selectedFile: selectedFile);
    } else {
      return Center(child: Text("未设计打开该文件的组件:\n$selectedFile"));
    }
  }

  Future<Widget> _loadFileViewer(String selectedFile) async {
    return _buildFileViewer(selectedFile);
  }
}