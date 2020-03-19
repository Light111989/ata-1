import 'package:ata/core/services/auth_service.dart';
import 'package:ata/ui/screens/home_screen.dart';
import 'package:ata/ui/screens/loading-screen.dart';
import 'package:ata/ui/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthRedirect extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    return FutureBuilder(
      future: authService.autoSignIn(),
      builder: (ctx, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return LoadingScreen();
        else
          return snapshot.data ? HomeScreen() : LoginScreen();
      },
    );
  }
}
