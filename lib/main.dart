import 'package:flutter/material.dart';
import 'package:photo_editor/injection_container.dart';
import 'package:photo_editor/features/presentation/pages/photo_editor_page.dart';

import 'package:google_fonts/google_fonts.dart';


void main() async{
  await InjectionContainer().init();
  runApp(const CapCutLiteApp());
}

class CapCutLiteApp extends StatelessWidget {
  const CapCutLiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CapCut Lite',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          primary: Colors.deepPurple,
          secondary: Colors.blue,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),  // Beautiful font
        cardTheme:  CardThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
      home:  PhotoEditorScreen(repository: sl(),),
      debugShowCheckedModeBanner: false,
    );
  }
}