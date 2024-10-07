import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:smart_attendance/screens/persons_screen.dart';
import 'package:smart_attendance/screens/scan_qr_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Code Scanner',
      theme: ThemeData(colorSchemeSeed: Color(0xff101826)),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  PersistentTabController _controller = PersistentTabController(initialIndex: 0);

  List<Widget> _buildScreens() {
    return [
      ScanQrScreen(),
      PersonsScreen()
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: Icon(CupertinoIcons.camera_viewfinder),
        title: ("Scan"),
        activeColorPrimary: Color(0xff4277FF),
        inactiveColorPrimary: Color(0xff6F99FC),
        activeColorSecondary: Color(0xffFFFFFE),
      ),
      PersistentBottomNavBarItem(
        icon: Icon(CupertinoIcons.person_2_alt),
        title: ("Persons"),
        activeColorPrimary: Color(0xff4277FF),
        inactiveColorPrimary: Color(0xff6F99FC),
        activeColorSecondary: Color(0xffFFFFFE),
      ),
    ];
  }

  @override
  void initState() {
    _controller.addListener(() => setState(() {

    }),);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Color(0xff1F2936),
      body: PersistentTabView(
        context,
        controller: _controller,
        screens: _buildScreens(),
        items: _navBarsItems(),
        handleAndroidBackButtonPress: true, // Default is true.
        resizeToAvoidBottomInset: true, // This needs to be true if you want to move up the screen on a non-scrollable screen when keyboard appears. Default is true.
        stateManagement: true, // Default is true.
        hideNavigationBarWhenKeyboardAppears: true,
        popBehaviorOnSelectedNavBarItemPress: PopBehavior.all,
        padding: const EdgeInsets.all(8),
        backgroundColor: Color(0xff101826),
        isVisible: true,
        animationSettings: const NavBarAnimationSettings(
          navBarItemAnimation: ItemAnimationSettings( // Navigation Bar's items animation properties.
            duration: Duration(milliseconds: 400),
            curve: Curves.ease,
          ),
          screenTransitionAnimation: ScreenTransitionAnimationSettings( // Screen transition animation on change of selected tab.
            animateTabTransition: true,
            duration: Duration(milliseconds: 200),
            screenTransitionAnimationType: ScreenTransitionAnimationType.fadeIn,
          ),
        ),
        confineToSafeArea: true,
        navBarHeight: kBottomNavigationBarHeight+20,
        navBarStyle: NavBarStyle.style7,
        floatingActionButton: _controller.index==1?Padding(
          padding: const EdgeInsets.all(8.0),
          child: FloatingActionButton(
            onPressed: (){
              showDialog(context: context, builder: (context) => Material(
                child: Container(
                  color: Color(0xff1F2936),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: Row(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Color(0xff4277FF),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0xff4277FF).withOpacity(0.75),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      padding: EdgeInsets.all(12),
                                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xffFFFFFE),),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Text(
                              'Add New One',
                              style: TextStyle(color: Color(0xffFFFFFE), fontSize: 22, fontWeight: FontWeight.bold, shadows: [BoxShadow(color: Color(0xffFFFFFE).withOpacity(0.75), blurRadius: 4,)]),
                            ),
                            Expanded(
                              child: SizedBox(),
                            ),
                          ],
                        ),
                        SizedBox(height: 32,),
                        TextFormField(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Color(0xff4277FF))
                            ),
                            hintText: 'Name',
                            focusColor: Color(0xff4277FF),
                            hintStyle: TextStyle(
                              color: Color(0xffFFFFFE).withOpacity(0.75),
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          style: TextStyle(
                            color: Color(0xffFFFFFE),
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                          keyboardType: TextInputType.name,
                        ),
                        SizedBox(height: 8,),
                        TextFormField(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Color(0xff4277FF))
                            ),
                            hintText: 'Birth Date',
                            focusColor: Color(0xff4277FF),
                            hintStyle: TextStyle(
                              color: Color(0xffFFFFFE).withOpacity(0.75),
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          style: TextStyle(
                            color: Color(0xffFFFFFE),
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                          keyboardType: TextInputType.datetime,
                        ),
                        SizedBox(height: 8,),
                        TextFormField(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Color(0xff4277FF))
                            ),
                            hintText: 'Address',
                            focusColor: Color(0xff4277FF),
                            hintStyle: TextStyle(
                              color: Color(0xffFFFFFE).withOpacity(0.75),
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          style: TextStyle(
                            color: Color(0xffFFFFFE),
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                          keyboardType: TextInputType.streetAddress,
                        ),
                        Expanded(child: SizedBox()),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: GestureDetector(
                            onTap: () {

                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Color(0xff4277FF),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xff4277FF).withOpacity(0.75),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.all(8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Save',
                                    style: TextStyle(color: Color(0xffFFFFFE), fontSize: 22, fontWeight: FontWeight.bold, shadows: [BoxShadow(color: Color(0xffFFFFFE).withOpacity(0.75), blurRadius: 4,)]),
                                  ),
                                  SizedBox(width: 64,),
                                  Icon(
                                    Icons.done_outline_rounded,
                                    color: Color(0xffFFFFFE),
                                    shadows: [
                                      BoxShadow(
                                        color: Color(0xffFFFFFE).withOpacity(0.75),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),);
            },
            child: Icon(
              Icons.add_rounded,
              color: Color(0xffFFFFFE),
              shadows: [
                BoxShadow(
                  color: Color(0xffFFFFFE).withOpacity(0.75),
                  blurRadius: 4,
                ),
              ],
            ),
            backgroundColor: Color(0xff101826),
          ),
        ):null,
        decoration: NavBarDecoration(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
          colorBehindNavBar: Color(0xff1F2936),
        ),
      ),
    );
  }
}