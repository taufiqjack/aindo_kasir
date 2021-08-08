import 'dart:async';
import 'dart:convert';

import 'package:aindo_kasir/controller/internet.dart';
import 'package:aindo_kasir/controller/syncToLocal.dart';
import 'package:aindo_kasir/database/SQFLite.dart';
import 'package:aindo_kasir/layout/menu.dart';
import 'package:aindo_kasir/models/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:modal_progress_hud_alt/modal_progress_hud_alt.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:page_transition/page_transition.dart';

class LoginApps extends StatefulWidget {
  LoginApps({Key? key}) : super(key: key);

  @override
  _LoginAppsState createState() => _LoginAppsState();
}

class _LoginAppsState extends State<LoginApps> {
  final GlobalKey<FormState> formKey = GlobalKey();
  late String uname;
  late String password;
  bool isAsync = false;
  bool isLoading = false;
  bool obsecureText = true;
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  void togglePass() {
    setState(() {
      obsecureText = !obsecureText;
    });
  }

  late Map data;
  late List userData;

  Future login() async {
    setState(() {
      isAsync = true;
    });

    uname = usernameController.text;
    password = passwordController.text;

    var data = {'username': uname, 'password': password, 'success': isAsync};

    var response =
        await http.post(Uri.parse(BaseUrl.login), body: json.encode(data));

    Map<String, dynamic> msg = jsonDecode(response.body);

    if (msg['msg'] == 'Berhasil') {
      SharedPreferences pref = await SharedPreferences.getInstance();
      pref.setBool('success', true);

      Future.delayed(Duration(seconds: 2), () {
        Navigator.push(
          context,
          PageTransition(
            type: PageTransitionType.fade,
            child: MenuKasir(),
          ),
        );
      });
      usernameController.clear();
      passwordController.clear();
      loadFromAPI();
      loadFromJenisBarangAPI();

      var token = msg['data']['token'];

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? message = prefs.getString('token');
      message = jsonEncode(token.toString());
      prefs.setString('token', message);
      print('token : $token');
    } else if (msg['msg'] == 'Username atau Password salah') {
      SharedPreferences pref = await SharedPreferences.getInstance();
      pref.setBool('success', false);

      setState(() {
        isAsync = false;
      });

      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Center(
                child: Text(
                  msg['msg'],
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15),
                ),
              ),
              actions: [
                Center(
                  child: TextButton(
                      onPressed: () {
                        setState(() {
                          if (formKey.currentState!.validate()) {
                            Navigator.of(context).pop();
                          }
                        });
                      },
                      child: Text('OK'),
                      style: ButtonStyle(
                          shape: MaterialStateProperty.all(
                              RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8))),
                          foregroundColor:
                              MaterialStateProperty.all(Colors.white),
                          backgroundColor:
                              MaterialStateProperty.all(Colors.grey),
                          fixedSize: MaterialStateProperty.all(Size(70, 30)))),
                ),
              ],
            );
          });
    }
  }

  void submit() {
    ConnectInternet.isInternet().then((connection) {
      if (connection) {
        setState(() {
          isLoading = true;
        });

        Future.delayed(Duration(seconds: 1), () {
          login();
          isLoading = false;
        });

        print("Koneksi Internet Tersedia");
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Tidak Ada Jaringan!")));
      }
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade900,
      body: WillPopScope(
        onWillPop: exitApp,
        child: ModalProgressHUD(
          inAsyncCall: isAsync,
          progressIndicator: CircularProgressIndicator(),
          opacity: 0.5,
          child: SingleChildScrollView(
            child: Center(
              child: Container(
                child: Column(
                  children: [
                    Container(
                      height: 50,
                      margin: EdgeInsets.all(125),
                      padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(
                          Radius.circular(
                            5.0,
                          ),
                        ),
                      ),
                      child: Image.asset(
                        "assets/images/fiesto.png",
                        height: 100,
                        width: 120,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(40),
                      height: 350,
                      width: 300,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.all(Radius.circular(10.0))),
                      child: SingleChildScrollView(
                        child: Form(
                          key: formKey,
                          child: Column(children: [
                            new Text(
                              "Login Akun",
                              style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.indigo.shade900,
                                  fontWeight: FontWeight.bold),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            new TextFormField(
                              controller: usernameController,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(hintText: 'Username'),
                              validator: (value) {
                                if (value.toString().isEmpty) {
                                  return 'Username tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            new TextFormField(
                              controller: passwordController,
                              textInputAction: TextInputAction.done,
                              obscureText: obsecureText,
                              decoration: InputDecoration(
                                  hintText: 'Password',
                                  suffixIcon: GestureDetector(
                                    child: Icon(
                                      obsecureText
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: obsecureText
                                          ? Colors.grey
                                          : Colors.blue.shade900,
                                    ),
                                    onTap: () {
                                      togglePass();
                                    },
                                  )),
                              validator: (value) {
                                if (value!.trim().isEmpty) {
                                  return 'Password tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                            SizedBox(
                              height: 40,
                            ),
                            !isLoading
                                ? SingleChildScrollView(
                                    child: TextButton(
                                        onPressed: () {
                                          setState(() {
                                            if (formKey.currentState!
                                                .validate()) {
                                              submit();

                                              setState(() {
                                                isLoading = true;
                                              });
                                            }
                                          });
                                        },
                                        child: Text('LOGIN'),
                                        style: ButtonStyle(
                                            shape: MaterialStateProperty.all(
                                                RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8))),
                                            foregroundColor:
                                                MaterialStateProperty.all(
                                                    Colors.white),
                                            backgroundColor:
                                                MaterialStateProperty.all(
                                                    Colors.indigo.shade900),
                                            fixedSize:
                                                MaterialStateProperty.all(
                                                    Size(150, 50)))),
                                  )
                                : Container(),
                          ]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> exitApp() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Konfirmasi Keluar"),
          content: Text("Apa anda yakin ingin keluar dari aplikasi ini?"),
          actions: <Widget>[
            TextButton(
              child: Text(
                "Tidak",
              ),
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all(Colors.black),
                textStyle: MaterialStateProperty.all(
                    TextStyle(fontWeight: FontWeight.bold)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Ya"),
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all(Colors.black),
                textStyle: MaterialStateProperty.all(
                    TextStyle(fontWeight: FontWeight.bold)),
              ),
              onPressed: () {
                SystemNavigator.pop();
              },
            ),
          ],
        );
      },
    );
    return false;
  }

  Future loadFromAPI() async {
    setState(() {
      var apiProvider = SyncToLocal();
      apiProvider.getAllBarangtoLocal();
      SQFliteBarang.sql.getBarang();
      SQFliteBarang.sql.getBarangFromJenis();
      SQFliteBarang.sql.getBarangFromJenis3();
      SQFliteBarang.sql.getBarangFromJenis4();
    });

    print(SQFliteBarang.sql.getBarang.toString());
  }

  Future loadFromJenisBarangAPI() async {
    setState(() {
      var apiProvider = SyncToLocal();
      apiProvider.getAllJenisBarangtoLocal();
      SQFliteBarang.sql.getJenisBarang();
    });

    print(SQFliteBarang.sql.getJenisBarang().toString());
  }

  Future isInternet() async {
    await ConnectInternet.isInternet().then((connection) {
      if (connection) {
        print("Koneksi Internet Tersedia");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Tidak Ada Jaringan Terhubung")));
      }
    });
  }

  @override
  void initState() {
    super.initState();
    isInternet();
  }
}
