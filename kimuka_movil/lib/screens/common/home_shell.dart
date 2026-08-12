import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../admin/admin_shell.dart';
import '../empleado/empleado_shell.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    if (user.esAdmin) {
      return AdminShell(user: user);
    }
    return EmpleadoShell(user: user);
  }
}
