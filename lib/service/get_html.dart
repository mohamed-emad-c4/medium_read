import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class previewArticale extends StatefulWidget {
  final String pageContent;

  previewArticale({super.key, required this.pageContent});

  @override
  _previewArticaleState createState() => _previewArticaleState();
}

class _previewArticaleState extends State<previewArticale> {
  String filePath = '';
  WebViewController? controller;
  bool isLoading = true; // To handle loading state

  @override
  void initState() {
    super.initState();
    getHttp();
  }

  Future<void> getHttp() async {
    var url = Uri.parse('https://freedium.cfd/${widget.pageContent}');

    var request = http.Request('GET', url);

    try {
      var streamedResponse = await request.send();

      Directory tempDir = await getTemporaryDirectory();
      String tempFilePath = '${tempDir.path}/temp.html';

      File file = File(tempFilePath);
      IOSink sink = file.openWrite();

      await streamedResponse.stream.transform(utf8.decoder).listen((value) {
        sink.write(value);
      }).asFuture();

      await sink.close();

      await editHtmlFile(tempFilePath);

      setState(() {
        filePath = tempFilePath;

        controller = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadFile('file://$filePath')
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: (_) => setState(() {
                isLoading = false;
              }),
            ),
          );
      });

      print('File saved and modified at $filePath');
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false; // Stop loading if there's an error
      });
    }
  }

  Future<void> editHtmlFile(String tempFilePath) async {
    File file = File(tempFilePath);
    List<String> lines = await file.readAsLines();

    List<int> linesToDelete = [
      9, 26, 27, 28, 29, 30,
      for (int i = 44; i < 95; i++) i,
      99, 102, 105, 115, 120, 121,
    ];

    linesToDelete.sort((a, b) => b.compareTo(a));
    for (int lineNum in linesToDelete) {
      if (lineNum <= lines.length) {
        lines.removeAt(lineNum - 1);
      }
    }

    await file.writeAsString(lines.join('\n'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Article'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Stack(
        children: [
          if (controller != null && filePath.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: WebViewWidget(
                controller: controller!,
              ),
            ),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          if (!isLoading && filePath.isEmpty)
            const Center(
              child: Text(
                'Failed to load content. Please try again.',
                style: TextStyle(fontSize: 18, color: Colors.redAccent),
              ),
            ),
        ],
      ),
    );
  }
}
