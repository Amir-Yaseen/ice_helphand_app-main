import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ice_helphand/models/added_contacts.dart';
import 'package:ice_helphand/models/payload.dart';
import 'package:ice_helphand/provider/auth_provider.dart';
import 'package:ice_helphand/size_config.dart';
import 'package:provider/provider.dart';
import 'package:shake/shake.dart';
import 'package:twilio_flutter/twilio_flutter.dart';
import '../../models/notification.dart';
import '../../models/notification_body.dart';
import '../../provider/contacts_provider.dart';
import '../../services/notification_services.dart';
import '../../static_variables.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = "/HomeScreen";
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TwilioFlutter? twilioFlutter;
  List<AddedContacts>? contactsList;
  NotificationService notificationService = NotificationService();
  FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;
  String? token;
  int _selectedCategoryIndex = 0;
  final AuthProvider auth = AuthProvider();
  String? selectedText;
  String? selectedBody;
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');
       String? fName ;
       String? lName;
       String? helpSeekerImage;
  List<Map> cards = [
    {'title': 'Theft Spotted', 'body': 'He Got Robbed Help Him'},
    {'title': 'I Have Accident', 'body': 'Accident Spotted Help Him'},
    {'title': 'I Am Injured', 'body': 'Help Him He is Injued'},
    {'title': 'Petrol Need', 'body': 'He Need Petrol Help Him'},
  ];
  // static Position? _currentPosition;
  // Future<bool> _handleLocationPermission() async {
  //   bool serviceEnabled;
  //   LocationPermission permission;

  //   serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //   if (!serviceEnabled) {
  //     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //         content: Text(
  //             'Location services are disabled. Please enable the services')));
  //     return false;
  //   }
  //   permission = await Geolocator.checkPermission();
  //   if (permission == LocationPermission.denied) {
  //     permission = await Geolocator.requestPermission();
  //     if (permission == LocationPermission.denied) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text('Location permissions are denied')));
  //       return false;
  //     }
  //   }
  //   if (permission == LocationPermission.deniedForever) {
  //     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //         content: Text(
  //             'Location permissions are permanently denied, we cannot request permissions.')));
  //     return false;
  //   }
  //   return true;
  // }

  // void updateLocation(double latitude, double longitude) {
  //   GeoPoint location = GeoPoint(latitude, longitude);
  //   firebaseFirestore.collection("usersLocation").doc(user!.uid).update({
  //     "location": location,
  //   });
  //   print('locationssss${location.latitude}');
  // }

  // Future<void> _getCurrentPosition() async {
  //   // final hasPermission = await _handleLocationPermission();
  //   // print('has permission${hasPermission}');
  //   // print('object');
  //   bool? hasPermission = MyStaticVariables.getHasPermission();
  //   if (!(hasPermission!)){
  //     print('no Permission');
  //     return;
  //   } 
  //   Geolocator.getPositionStream().listen((Position position) {
  //     print('position donesad');
  //     MyStaticVariables.setMyStaticVariable(position);
  //     updateLocation(position.latitude, position.longitude);
  //   });
  // }

  @override
  void initState() {
    // _getCurrentPosition().then((_) {
    //   // print('main current position done');
    //   //   // print('then');
    //   //   // setUserName();
    //   //   // locationData();
    // });
    ShakeDetector detector = ShakeDetector.autoStart(
      onPhoneShake: () {
        sendSmsToAll();
        notifyInRange();
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(
        //     content: Text('Shake!'),
        //   ),
        // );
        print('shaked');
        // Do stuff on phone shake
      },
      minimumShakeCount: 1,
      shakeSlopTimeMS: 500,
      shakeCountResetTime: 3000,
      shakeThresholdGravity: 2.7,
    );
    twilioFlutter = TwilioFlutter(
        accountSid:
            'AC909353b4c667a622d0515ae7909e8282', // replace *** with Account SID
        authToken:
            '2a1aa1fe8957e44f640d51a6c300afc4', // replace xxx with Auth Token
        twilioNumber: '+13612829068' // replace .... with Twilio Number
        );
    Provider.of<ContactsProvider>(context, listen: false).fetchContacts();

    contactsList =
        Provider.of<ContactsProvider>(context, listen: false).getaddedContacts;

    // print("xxxx${contactsList!.length}");
    // pno();
    // print('twillo called');
    super.initState();
  }
  // void needHelp(){
  //   firebaseFirestore.collection("users").doc(user!.uid).set({
  //     "needHelp": true,
  //   },SetOptions(merge: true));
  // }
  void notifyInRange() {
    print('notificatioon');
    Future<QuerySnapshot<Map<String, dynamic>>> querySnapshot =
        firebaseFirestore.collection("users").get();
    querySnapshot.then((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        for (int i = 0; i < snapshot.docs.length; i++) {
          // print("//${snapshot.docs[i].data()['uid']}");
          print("//${snapshot.docs[i].data()['inRange']}");

          // print(token);
          // getToken(snapshot.docs[i].data()['uid']);

          if (snapshot.docs[i].data()['uid'] != user!.uid &&
              snapshot.docs[i].data()['inRange'] == true) {
            // print("if:${snapshot.docs[i].data()['uid']}");
            // needHelp();
            
            getToken(snapshot.docs[i].data()['uid']);
            // print(snapshot.docs[i].data());
            // getToken(snapshot.docs[i].data()['uid']);
            // print('Amir');
            // // print(token);
            // sendNotification(token, selectedText ?? cards[0]['title'],
            //     selectedBody ?? cards[0]['body']);
          }
        }
      }
    });
  }

  void getToken(String uid) {
    Future<QuerySnapshot<Map<String, dynamic>>> querySnapshot =
        firebaseFirestore
            .collection('users')
            .doc(uid)
            .collection('token')
            .get();
    querySnapshot.then((snapshot) {
      token = snapshot.docs.first.id;
      print(token);
      sendNotification(token, selectedText ?? cards[0]['title'],
          selectedBody ?? cards[0]['body']);
      // print(token);
    });
  }

  void sendNotification(String? token, String? title, String? body) {
    notificationService.createNotification(MyNotification(
        to: token,
        notification: NotificationBody(title: title, body: body),
        payload: Payload(type: 'msj', isNotification: '1')));
    print('notification called');
  }
  // List<String> clsit = ['+923115838578', '+923468544378', '+923468544378'];

  void sendSmsToAll() {
    // Position? pos = MyStaticVariables.getCurrentPosition();
    // twilioFlutter!.sendSMS(toNumber: "+923115838578", messageBody: 'Help Me. I am at ${MyStaticVariables.getCurrentPosition()}');
    
    print('sms call');
    for (var element in contactsList!) {
      print("sms smnd${element.phNo!.first.value}");
      print(element.phNo!.first.value.toString());
      twilioFlutter!.sendSMS(
          toNumber: element.phNo!.first.value.toString(), messageBody: 'Help Me. I am at ${MyStaticVariables.getCurrentPosition()}');
    }
  }
  
 void sendInAppNotification(){
  usersCollection.doc(user!.uid).get().then((value) {
    fName = value.get('firstName');
    lName = value.get('lastName');
    helpSeekerImage = value.get('image');
  }).then((value) {
    usersCollection.doc(user!.uid).collection('inRangeUsers').get().then((value) {
    value.docs.forEach((element) { 
      usersCollection.doc(element.id).update({
      'needHelp': true,
      'seekerName': '$fName $lName',
      'seekersUid': user!.uid,
      'time':FieldValue.serverTimestamp(),
      'helpSeekerImage':helpSeekerImage,
      'emergencySituation':selectedText??cards[0]['title'],

    });
    });
    // print(value.docs.first.id);
  });
  });

  // helpSeeker['username'];/
  
  // usersCollection.doc(user!.uid).update({
  //     'needHelp': true,
  //     'seekerName': FieldValue.serverTimestamp(),
  //   });
 }
  // Future<void> call() async {
  //   HttpsCallable callable =
  //       FirebaseFunctions.instance.httpsCallable('helloWorld');
  //   final results = await callable();
  //   print(results);
  // }
  // final response = await functions.call();

  @override
  Widget build(BuildContext context) {
    // final AuthProvider authProvider = AuthProvider();
    return Scaffold(
      body: Center(
          child: SizedBox(
        height: getProportionateScreenHeight(700),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: getProportionateScreenWidth(200),
              child: const Text(
                'Emergency Help Needed?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
              ),
            ),
            SizedBox(
              height: getProportionateScreenHeight(40),
            ),
            InkWell(
                onTap: () {
                  print('call');
                  sendInAppNotification();
                  // MyStaticVariables.getCurrentPosition();
                  sendSmsToAll();
                  notifyInRange();
                  // FirebaseInAppMessaging.instance.triggerEvent("");

            // FirebaseMessaging.instance.sendMessage();

            // FirebaseMessaging.instance.getInitialMessage();
                  //
                  // notificationService.createNotification(MyNotification(
                  //     to:
                  //         "erY7HqsPTy2PaVtxZ4tpqG:APA91bEd6aFVObqJtlPKLxSS7pipYCE3wM_LHkb9SdV9QHngSQzQXFMtVoir_orrvtoS0ExYLGC3qP_RD_EBlet-ELoKNvMlKohhbE90swOvQ44F0ZGNWEAzSlZm4YT_Qs38iX4vHj-l",
                  //     notification: NotificationBody(
                  //         title: "Test", body: "Notification Testing")));

                  // sendSmsToAll();

                  // twilioFlutter!.sendSMS(
                  //     toNumber: '+923115838578', messageBody: 'hello world');
                },
                child: Image.asset('assets/images/Alertbutton.png')),
            SizedBox(
              height: getProportionateScreenHeight(80),
            ),
            const Text(
              'Choose the emergency Situation',
              style: TextStyle(fontSize: 12),
            ),
            SizedBox(
              height: getProportionateScreenHeight(20),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                height: getProportionateScreenHeight(130),
                width: getProportionateScreenWidth(400),
                child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: cards.length,
                    itemBuilder: (context, index) {
                      return CategoryCard(
                        text: cards[index]['title'],
                        isSelected: _selectedCategoryIndex == index,
                        onTap: () {
                          setState(() {
                            _selectedCategoryIndex = index;
                            selectedText = cards[index]['title'];
                            selectedBody = cards[index]['body'];
                          });
                        },
                      );
                    }),
              ),
            ),
            // TextButton(
            //     onPressed: () {
            //       auth.signout();
            //     },
            //     child: Text('Logout'))
          ],
        ),
      )),
    );
  }
}

class CategoryCard extends StatefulWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;
  // String selectedText
  CategoryCard({
    required this.text,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  //  bool isSelected = widget.index == widget.selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
            height: getProportionateScreenHeight(80),
            width: getProportionateScreenWidth(140),
            decoration: BoxDecoration(
                color: widget.isSelected
                    ? Color.fromARGB(255, 223, 223, 223)
                    : Colors.white,
                borderRadius: BorderRadius.circular(10)),
            // color: Colors.amber,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 15, left: 15),
                  child: SizedBox(
                    width: getProportionateScreenWidth(80),
                    child: Text(
                      widget.text,
                      textAlign: TextAlign.start,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset('assets/images/icons8-circled.png'),
                    Image.asset('assets/images/icons8-accident.png')
                  ],
                ),

                // SvgPicture.asset(
                //   'assets/icons/circlearow.svg',
                // )
              ],
            )),
      ),
    );
  }
}
