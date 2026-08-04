import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

import 'login_screen.dart';

class HomeScreen extends StatelessWidget {

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text("Inicio"),

        actions: [

          IconButton(

            onPressed: () async {

              await context.read<AuthProvider>().logout();

              Navigator.pushReplacement(

                context,

                MaterialPageRoute(

                  builder: (_) => const LoginScreen(),

                ),

              );

            },

            icon: const Icon(Icons.logout),

          )

        ],

      ),

      body: const Center(

        child: Text(

          "Login Correcto",

          style: TextStyle(

            fontSize: 25,

          ),

        ),

      ),

    );

  }

}