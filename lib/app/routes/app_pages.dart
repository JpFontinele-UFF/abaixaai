import 'package:abaixaai/app/bindings/home_bindings.dart';
import 'package:abaixaai/app/bindings/login_bindings.dart';
import 'package:abaixaai/app/bindings/user_bindings.dart';
import 'package:abaixaai/app/routes/app_routes.dart';
import 'package:abaixaai/app/ui/pages/home_page.dart';
import 'package:abaixaai/app/ui/pages/initial_page.dart';
import 'package:abaixaai/app/ui/pages/login_page.dart';
import 'package:abaixaai/app/ui/pages/measurement_page.dart';
import 'package:get/get.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: Routes.INITIAL,
      page: () => const InitialPage(),
    ),
    GetPage(name: Routes.LOGIN, page: () => const LoginPage(), binding: LoginBinding()),
    
    GetPage(name: Routes.HOME, page: () => HomePage(), bindings: [HomeBinding(), UserBinding()]),

    // Adicione esta rota
GetPage(
  name: Routes.MEASUREMENT_PAGE,
  page: () => MeasurementPage(),
),

  ];
}
