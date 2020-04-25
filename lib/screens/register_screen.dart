import 'dart:io';

import 'package:covid19/screens/otp_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:location/location.dart';

import 'map_screen.dart';

class RegisterScreen extends StatefulWidget {
  static const routeName = '/RegisterScreen';

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final phoneNoController = TextEditingController();
  final countryCodeController = TextEditingController(text: '+60');

  Location location = new Location();

  bool _serviceEnabled;
  PermissionStatus _permissionGranted;
  LocationData _locationData;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      EasyLoading.show(status: 'auto login...');
    });
    _checkPermission().then((onValue) {
      if (onValue == true) {
        _tryAutoLogin();
      } else {
        exit(0);
      }
    });
  }

  Future<bool> _checkPermission() async {
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return false;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return false;
      }
    }
    return true;
  }

  Future<void> _tryAutoLogin() async {
    final FirebaseUser user = await FirebaseAuth.instance.currentUser();

    if (user != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        EasyLoading.dismiss();
        Navigator.of(context).pushReplacementNamed(MapScreen.routeName);
      });
    } else {
      EasyLoading.dismiss();
    }

    /*final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userAuth')) {
      print('No Data');
      EasyLoading.dismiss();
      return;
    }

    final userAuth =
        json.decode(prefs.getString('userAuth')) as Map<String, Object>;
    print(userAuth.toString());

    this._phoneAuthCredential = PhoneAuthProvider.getCredential(
        verificationId: userAuth['verificationId'],
        smsCode: userAuth['smsCode']);
    if (userAuth['verificationId'] != null && userAuth['smsCode'] != null) {
      try {
        print(this._phoneAuthCredential.toString());

        await FirebaseAuth.instance
            .signInWithCredential(this._phoneAuthCredential)
            .then(
          (AuthResult authRes) {
            print(authRes.toString());

            EasyLoading.dismiss();

            Navigator.of(context).pushReplacementNamed(MapScreen.routeName);
          },
        );
      } on AuthException catch (e) {
        print(e.message.toString());

        EasyLoading.dismiss();
      } catch (e) {
        print(e.message.toString());

        EasyLoading.dismiss();
      }
    }*/
  }

  @override
  Widget build(BuildContext context) {
    return FlutterEasyLoading(
        child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.green,
              title: Text(
                'Register',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            backgroundColor: Color(0xFFeaeaea),
            body: ListView(
              shrinkWrap: true,
              scrollDirection: Axis.vertical,
              children: <Widget>[
                Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 16.0, top: 20.0, right: 16.0),
                        child: Text(
                          "Enter your phone number",
                          style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 30.0),
                        child: Image(
                          image: AssetImage('assets/images/otp-icon.png'),
                          height: 120.0,
                          width: 120.0,
                        ),
                      ),
                      Row(
                        children: <Widget>[
                          Flexible(
                            child: new Container(),
                            flex: 1,
                          ),
                          Flexible(
                            child: new TextFormField(
                              controller: countryCodeController,
                              textAlign: TextAlign.center,
                              autofocus: false,
                              style: TextStyle(
                                  fontSize: 20.0, color: Colors.black),
                            ),
                            flex: 3,
                          ),
                          Flexible(
                            child: new Container(),
                            flex: 1,
                          ),
                          Flexible(
                            child: new TextFormField(
                              textAlign: TextAlign.start,
                              controller: phoneNoController,
                              autofocus: false,
                              enabled: true,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              style: TextStyle(
                                  fontSize: 20.0, color: Colors.black),
                            ),
                            flex: 9,
                          ),
                          Flexible(
                            child: new Container(),
                            flex: 1,
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 40.0, bottom: 40.0),
                        child: new Container(
                          height: 50.0,
                          child: new RaisedButton(
                              onPressed: () => goToOTP(),
                              child: Text('Get Verification Code'),
                              textColor: Colors.white,
                              color: Colors.green,
                              shape: new RoundedRectangleBorder(
                                  borderRadius:
                                      new BorderRadius.circular(30.0))),
                        ),
                      )
                    ])
              ],
            )));
    // TODO: implement build
  }

  goToOTP() {
    if (countryCodeController.text.length > 1 &&
        phoneNoController.text.length > 6) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OtpScreen(
            phone: '${countryCodeController.text} ${phoneNoController.text}',
          ),
        ),
      );
    } else {
      Fluttertoast.showToast(
          msg: 'Your phone number is invalid!',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
    }
  }
}
