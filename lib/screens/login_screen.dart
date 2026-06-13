import 'package:finance_control/core/auth/auth_service.dart';
import 'package:finance_control/core/models/user.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    LoginScreen({super.key});

    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text("Login into you account!"),
          backgroundColor: Colors.greenAccent,
        ),
        body: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 60, bottom: 10),
                  child: Center(
                    child: Container(
                      height: 150,
                      width: 200,
                      child: FlutterLogo(),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  child: TextFormField(
                    controller: emailController,
                    validator: (value) {
                      if (value != null &&
                          value.isNotEmpty &&
                          value.trim().isNotEmpty) {
                        return null;
                      }
                      return "* not empty";
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      label: Text("E-mail"),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsGeometry.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  child: TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    validator: (value) {
                      if (value != null &&
                          value.isNotEmpty &&
                          value.trim().isNotEmpty) {
                        return null;
                      }
                      return "* cannot be empty";
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      label: Text("Password"),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => print("Forgot the password."),
                  child: Text(
                    "Forgot the password?",
                    style: TextStyle(color: Colors.blue, fontSize: 15),
                  ),
                ),
                Container(
                  height: 50,
                  width: 250,
                  child: ElevatedButton(
                    onPressed: () async {
                      bool valid = _formKey.currentState!.validate();
                      if (valid) {
                        final User? user = await AuthService().login(
                          emailController.text,
                          passwordController.text,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
