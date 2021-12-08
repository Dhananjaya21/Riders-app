import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:riderapp/AllWidgets/progressDialog.dart';
import 'package:riderapp/Allscreens/Mainscreen.dart';
import 'package:riderapp/Allscreens/registrationScreen.dart';
import 'package:riderapp/main.dart';

class loginscreen extends StatelessWidget {
  static const String idScreen="login";
  TextEditingController emailTextEditingController = TextEditingController();
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
                  "login as a User",
                style: TextStyle(fontSize: 35.0,fontFamily: "Brand Bold"),
                textAlign: TextAlign.center,
              ),

              Padding(
                  padding: EdgeInsets.all(20.0),
                child: Column(
                  children: [


                    SizedBox(height: 120.0,),
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
                            "Login",
                            style: TextStyle(fontSize: 18.0,fontFamily: "Brand Bold")
                          ),
                        )
                      ),
                      shape: new RoundedRectangleBorder(
                        borderRadius: new BorderRadius.circular(24.0),
                      ),
                      onPressed: (){
                        if(!emailTextEditingController.text.contains("@")){
                          displayToastMessage("Email address is not valid", context);
                        }
                        else if(passwordTextEditingController.text.length < 6){
                          displayToastMessage("Password cannot be empty!", context);
                        }
                        else{
                          loginAuthenticateUser(context);
                        }
                      },
                    ),


                  ],
                ),
              ),


              TextButton(
                  onPressed: (){
                    Navigator.pushNamedAndRemoveUntil(context, registrationScreen.idScreen, (route) => false);
                  },
                  child: Text("Do not have an Account?")
              )
            ],
          ),
        ),
      ),
    );
  }

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  void loginAuthenticateUser(BuildContext context) async{
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context){
          return ProgressDialog(message: "Authenticating,\n Please wait...",);
        }
    );

    final User? firebaseUser= (await _firebaseAuth.signInWithEmailAndPassword(
        email: emailTextEditingController.text,password: passwordTextEditingController.text
    ).catchError((errMsg){
      Navigator.pop(context);
      displayToastMessage("Error: " + errMsg.toString(), context);
    })).user;

    if (firebaseUser != null){

      usersRef.child(firebaseUser.uid).once().then((DataSnapshot snap){
        if(snap.value !=null)
        {
         Navigator.pushNamedAndRemoveUntil(context, Mainscreen.idScreen, (route) => false) ;
         displayToastMessage("You are logged-in.", context);
        }
        else
          {
            Navigator.pop(context);
            _firebaseAuth.signOut();
            displayToastMessage("User not found!!", context);
          }

      });

    }
    else{
      Navigator.pop(context);
      displayToastMessage("Error: can not sign in", context);

    }

  }
}
