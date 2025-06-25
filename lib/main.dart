import 'dart:io';

import 'package:flutter/material.dart';
import 'package:scuba_diving_admin_panel/main_page.dart';

String? API_BASE_URL;

void main() {
  runApp(const MyApp());
  HttpOverrides.global = MyHttpOverrides();

  API_BASE_URL = 'https://localhost:7096';
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: MainPage(),
    );
  }
}
