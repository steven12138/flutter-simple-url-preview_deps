import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:simple_url_preview_v2/simple_url_preview.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Url Preview Demo',
      theme: ThemeData(
        primaryColor: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue)
            .copyWith(secondary: Colors.white),
      ),
      home: const MyHomePage(title: 'Simple Url Preview Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String? title;

  const MyHomePage({super.key, this.title});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _url = '';

  _onUrlChanged(String updatedUrl) {
    setState(() {
      _url = updatedUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title!),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SimpleUrlPreview(
            url: _url,
            bgColor: Theme.of(context).colorScheme.secondary,
            isClosable: true,
            titleLines: 2,
            descriptionLines: 3,
            imageLoaderColor: Colors.white,
            previewHeight: 150,
            previewContainerPadding: const EdgeInsets.all(10),
            onTap: () => log('Hello Flutter URL Preview'),
            titleStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
            descriptionStyle: TextStyle(
              fontSize: 14,
              color: Theme.of(context).primaryColor,
            ),
            siteNameStyle: TextStyle(
              fontSize: 14,
              color: Theme.of(context).primaryColor,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              onChanged: (newValue) => _onUrlChanged(newValue),
              decoration: const InputDecoration(
                hintText: 'Enter the url',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
