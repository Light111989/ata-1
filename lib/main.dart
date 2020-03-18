import 'package:ata/providers.dart';
import 'package:ata/ui/widgets/auth_redirect.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ata/ui/screens/login_screen.dart';
import 'package:ata/ui/screens/home_screen.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return MultiProvider(
      providers: providers,
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.green,
        ),
        home: AuthRedirect(),
        routes: {
          HomeScreen.routeName: (_) => HomeScreen(),
          LoginScreen.routeName: (_) => LoginScreen(),
        },
      ),
    );
  }
}
