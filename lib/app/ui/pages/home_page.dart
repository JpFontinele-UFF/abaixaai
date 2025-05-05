import 'package:abaixaai/app/controller/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePage extends StatelessWidget {


   final HomeController _homeController = Get.put(HomeController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(_homeController.user.urlImage ?? "https://via.placeholder.com/150"),
            ),
            const SizedBox(height: 20),
            Text(
              "Bem-vindo(a),",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              _homeController.user.name ?? "Usuário",
              style: TextStyle(fontSize: 20, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}


