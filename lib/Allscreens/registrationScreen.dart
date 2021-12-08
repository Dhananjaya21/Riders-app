import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:riderapp/AllWidgets/progressDialog.dart';
import 'package:riderapp/Allscreens/Mainscreen.dart';
import 'package:riderapp/Allscreens/login%20screen.dart';
import 'package:flutter/services.dart';
import 'package:riderapp/main.dart';
class registrationScreen extends StatelessWidget {
  static const String idScreen="register";

  TextEditingController nameTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController phoneTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding:  EdgeInsets.all(8.0),
          child: Column(
            //crossAxisAlignment: CrossAxisAlignment.center,
            //mainAxisSize: MainAxisSize.max,
            //mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 50.0,),
              Image(image: AssetImage("images/logo4.png"),
                width: 500.0,
                height: 200.0,
                alignment: Alignment.topCenter,
              ),

              SizedBox(height: 35.0,),
              Text(
                "Register as an User",
                style: TextStyle(fontSize: 35.0,fontFamily: "Brand Bold"),
                textAlign: TextAlign.center,
              ),

              Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  children: [

                    SizedBox(height: 20.0,),
                    TextField(
                      controller: nameTextEditingController,
                      keyboardType: TextInputType.text ,
                      decoration: InputDecoration(
                          labelText: "Name",
                          labelStyle: TextStyle(fontSize: 14.0,),
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 10.0,
                          )
                      ),
                      style: TextStyle(fontSize: 14.0),
                    ),


                    SizedBox(height: 1.0,),
                    TextField(
                      controller: emailTextEditingController,
                      keyboardType: TextInputType.emailAddress ,
                      decoration: InputDecoration(
                          labelText: "Email",
                          labelStyle: TextStyle(fontSize: 14.0,),
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 10.0,
                          )
                      ),
                      style: TextStyle(fontSize: 14.0),
                    ),

                    SizedBox(height: 1.0,),
                    TextField(
                      controller: phoneTextEditingController,
                      keyboardType: TextInputType.phone ,
                      decoration: InputDecoration(
                          labelText: "Phone",
                          labelStyle: TextStyle(fontSize: 14.0,),
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 10.0,
                          )
                      ),
                      style: TextStyle(fontSize: 14.0),
                    ),

                    SizedBox(height: 1.0,),
                    TextField(
                      controller: passwordTextEditingController,
                      obscureText: true ,
                      decoration: InputDecoration(
                        labelText: "Password",
                        labelStyle: TextStyle(fontSize: 14.0,),
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 10.0,
                        ),
                      ),
                      style: TextStyle(fontSize: 14.0),
                    ),

                    SizedBox(height: 40.0,),
                    RaisedButton(
                      color: Colors.blue,
                      textColor: Colors.white,
                      child: Container(
                          height: 50.0,
                          child:Center(
                            child: Text(
                                "register",
                                style: TextStyle(fontSize: 18.0,fontFamily: "Brand Bold")
                            ),
                          )
                      ),
                      shape: new RoundedRectangleBorder(
                        borderRadius: new BorderRadius.circular(24.0),
                      ),
                      onPressed: ()
                      {
                        if(nameTextEditingController.text.length<4)
                        {
                          displayToastMessage("Name must include atleast 3 characters", context);
                        }
                        else if(!emailTextEditingController.text.contains("@")){
                          displayToastMessage("Email address is not valid", context);
                        }
                        else if(phoneTextEditingController.text.isEmpty){
                          displayToastMessage("Phone number can not be null.", context);
                        }
                        else if(passwordTextEditingController.text.length < 6){
                          displayToastMessage("Password must be atleast 6 characters", context);
                        }
                        else{
                          registerNewUser(context);
                        }
                        registerNewUser(context);
                      },
                    ),


                  ],
                ),
              ),


              FlatButton(
                  onPressed: (){
                    Navigator.pushNamedAndRemoveUntil(context, loginscreen.idScreen, (route) => false);
                  },
                  child: Text("Already have an Account?")
              )
            ],
          ),
        ),
      ),
    );
  }

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  void registerNewUser(BuildContext context) async
  {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context){
          return ProgressDialog(message: "Registering,\n Please wait...",);
        }
    );

    final User? firebaseUser= (await _firebaseAuth.createUserWithEmailAndPassword(
        email: emailTextEditingController.text,password: passwordTextEditingController.text
    ).catchError((errMsg){
      Navigator.pop(context);
      displayToastMessage("Error: " + errMsg.toString(), context);
    })).user;

    if (firebaseUser != null){

      Map userDataMap = {
        "name": nameTextEditingController.text.trim(),
        "email": emailTextEditingController.text.trim(),
        "phone": phoneTextEditingController.text.trim(),
      };

      usersRef.child(firebaseUser.uid).set(userDataMap);
      displayToastMessage("New Account has been created.", context);


      Navigator.pushNamedAndRemoveUntil(context, Mainscreen.idScreen, (route) => false);
    }
    else{
      Navigator.pop(context);
      displayToastMessage("New user account has not been created.", context);

    }

  }
}

displayToastMessage(String message, BuildContext context){
  Fluttertoast.showToast(msg: message);
}