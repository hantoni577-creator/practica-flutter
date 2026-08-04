import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

import '../widgets/custom_button.dart';

import '../widgets/custom_textfield.dart';

import 'home_screen.dart';

import 'register_screen.dart';

class LoginScreen extends StatefulWidget {

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();

}

class _LoginScreenState extends State<LoginScreen> {

  final email = TextEditingController();

  final password = TextEditingController();

  @override
  Widget build(BuildContext context) {

    final auth = context.read<AuthProvider>();

    return Scaffold(

      appBar: AppBar(

        title: const Text("Login"),

      ),

      body: Padding(

        padding: const EdgeInsets.all(20),

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            CustomTextField(

              controller: email,

              label: "Correo",

            ),

            CustomTextField(

              controller: password,

              label: "Contraseña",

              obscure: true,

            ),

            const SizedBox(height: 20),

            CustomButton(

              text: "Ingresar",

              onPressed: () async {

                await auth.login(

                  email.text,

                  password.text,

                );

                if (!context.mounted) return;

                if (auth.logged) {

                  Navigator.pushReplacement(

                    context,

                    MaterialPageRoute(

                      builder: (_) => const HomeScreen(),

                    ),

                  );

                } else {

                  ScaffoldMessenger.of(context).showSnackBar(

                    const SnackBar(

                      content: Text(

                        "Correo o contraseña incorrectos",

                      ),

                    ),

                  );

                }

              },

            ),

            TextButton(

              onPressed: () {

                Navigator.push(

                  context,

                  MaterialPageRoute(

                    builder: (_) => const RegisterScreen(),

                  ),

                );

              },

              child: const Text("Crear cuenta"),

            )

          ],

        ),

      ),

    );

  }

}