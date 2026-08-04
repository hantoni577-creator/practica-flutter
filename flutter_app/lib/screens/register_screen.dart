import 'package:flutter/material.dart';

import '../services/auth_service.dart';

import '../widgets/custom_button.dart';

import '../widgets/custom_textfield.dart';

class RegisterScreen extends StatefulWidget {

  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();

}

class _RegisterScreenState extends State<RegisterScreen> {

  final nombre = TextEditingController();

  final email = TextEditingController();

  final password = TextEditingController();

  final auth = AuthService();

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text("Registro"),

      ),

      body: Padding(

        padding: const EdgeInsets.all(20),

        child: Column(

          children: [

            CustomTextField(

              controller: nombre,

              label: "Nombre",

            ),

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

              text: "Registrar",

              onPressed: () async {

                bool ok = await auth.register(

                  nombre.text,

                  email.text,

                  password.text,

                );

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(

                  SnackBar(

                    content: Text(

                      ok

                          ? "Usuario registrado"

                          : "No fue posible registrar el usuario",

                    ),

                  ),

                );

                if (ok) {

                  Navigator.pop(context);

                }

              },

            )

          ],

        ),

      ),

    );

  }

}