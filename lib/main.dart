import 'package:abaixaai/app/routes/app_pages.dart';
import 'package:abaixaai/app/routes/app_routes.dart';
import 'package:abaixaai/app/ui/theme/app_theme.dart';
import 'package:abaixaai/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    GetMaterialApp(
      title: 'Abaixa Aí',
      debugShowCheckedModeBanner: false, //Etiqueta de Debug
      getPages: AppPages.routes,
      initialRoute: Routes.INITIAL,
      theme: appThemeData,
    ),
  );
}