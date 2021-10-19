import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:email_validator/email_validator.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:itzbill/providers/auth_provider.dart';
import 'package:itzbill/widgets/button_widget.dart';
import 'package:itzbill/widgets/loading_widget.dart';
import 'package:itzbill/widgets/toast_widget.dart';

import 'package:itzbill/config/strings.dart' as strings;

enum FormType { Login, Register }

class AuthScreen extends StatefulWidget {
  AuthScreen({Key? key}) : super(key: key);

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final formKey = new GlobalKey<FormState>();

  FormType formType = FormType.Login;

  FToast fToast = FToast();

  String? name;
  String? email;
  String? password;

  bool obscureText = true;
  bool loading = false;

  void moveToRegister() {
    formKey.currentState!.reset();
    setState(() {
      formType = FormType.Register;
    });
  }

  void moveToLogin() {
    formKey.currentState!.reset();
    setState(() {
      formType = FormType.Login;
    });
  }

  void toggle() {
    setState(() {
      obscureText = !obscureText;
    });
  }

  bool validateAndSave() {
    final form = formKey.currentState;
    if (form!.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  _startLoading() {
    loading = true;
    fToast.removeQueuedCustomToasts();
    Widget toast = LoadingWidget();
    fToast.showToast(
      child: toast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: Duration(seconds: 60),
    );
  }

  _stopLoading() {
    fToast.removeQueuedCustomToasts();
    loading = false;
  }

  Future<void> submit() async {
    if (loading) return;

    _startLoading();

    AuthProvider auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      if (formType == FormType.Login) {
        await auth.login(email!, password!);
        _stopLoading();
        _showToast("Login successful");
      } else if (formType == FormType.Register) {
        await auth.registerUser(email!, password!);
        _stopLoading();
        _showToast("Successful registration");
      }
    } on FirebaseAuthException catch (e) {
      _stopLoading();
      _showToast(e.message.toString(), true);
    } on Error catch (e) {
      _stopLoading();
      _showToast(e.toString(), true);
    }
  }

  Future<void> validateAndSubmit() async {
    if (validateAndSave()) {
      await submit();
    }
  }

  _showToast(String message, [bool error = false]) {
    Widget toast = ToastWidget(message: message, error: error);
    fToast.showToast(
      child: toast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: Duration(seconds: 2),
    );
  }

  @override
  void initState() {
    super.initState();
    loading = false;
    fToast.init(context);
  }

  @override
  void dispose() {
    super.dispose();
    loading = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Row(
          // mainAxisAlignment: MainAxisAlignment.,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                //color: Colors.blue,
                child: Form(
                  key: formKey,
                  child: Center(
                    child: Container(
                      width: 500,
                      padding: EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: buildInputs() + buildSubmitButtons(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> buildInputs() {
    if (formType == FormType.Login) {
      return [
        //TitleWidget(title: 'Login'),
        SizedBox(height: 24.0),
        TextFormField(
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(labelText: strings.email),
          validator: (value) => value!.isEmpty
              ? strings.emailError
              : EmailValidator.validate(value)
                  ? null
                  : strings.emailError,
          onSaved: (value) => email = value,
        ),
        SizedBox(height: 16.0),
        TextFormField(
          keyboardType: TextInputType.visiblePassword,
          decoration: InputDecoration(
            labelText: strings.password,
            suffixIcon: IconButton(
              icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
              onPressed: toggle,
            ),
          ),
          validator: (value) => value!.isEmpty ? strings.passwordError : null,
          onSaved: (value) => password = value,
          obscureText: obscureText,
        ),
      ];
    } else {
      return [
        //TitleWidget(title: 'Register'),
        SizedBox(height: 24.0),
        TextFormField(
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(labelText: strings.email),
          validator: (value) => value!.isEmpty
              ? strings.emailError
              : EmailValidator.validate(value)
                  ? null
                  : strings.emailError,
          onSaved: (value) => email = value,
        ),
        SizedBox(height: 16.0),
        TextFormField(
          keyboardType: TextInputType.visiblePassword,
          decoration: InputDecoration(
            labelText: strings.password,
            suffixIcon: IconButton(
              icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
              onPressed: toggle,
            ),
          ),
          validator: (value) => value!.isEmpty ? strings.passwordError : null,
          onSaved: (value) => password = value,
          obscureText: obscureText,
        ),
      ];
    }
  }

  List<Widget> buildSubmitButtons() {
    if (formType == FormType.Login) {
      return [
        SizedBox(height: 16),
        ButtonWidget(
          text: strings.login,
          onPressed: validateAndSubmit,
        ),
        SizedBox(height: 8.0),
        TextButton(
          child: Text(strings.register, style: TextStyle(fontSize: 20.0)),
          onPressed: moveToRegister,
        ),
      ];
    } else {
      return [
        SizedBox(height: 16),
        ButtonWidget(
          text: strings.register,
          onPressed: validateAndSubmit,
        ),
        SizedBox(height: 8.0),
        TextButton(
          child: Text(strings.haveAccount, style: TextStyle(fontSize: 20.0)),
          onPressed: moveToLogin,
        ),
      ];
    }
  }
}
