import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:smart_attendance/cubit/app_cubit.dart';
import 'package:smart_attendance/generated/assets.dart';
import 'package:smart_attendance/screens/persons_screen.dart';
import 'package:smart_attendance/screens/scan_qr_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_attendance/model/person.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  timeago.setLocaleMessages('en', MyCustomMessages());

  await Supabase.initialize(
    url: dotenv.env['URL']??'',
    anonKey: dotenv.env['ANONKEY']??'',
  );

  runApp(const MyApp());
}



// my_custom_messages.dart
class MyCustomMessages implements timeago.LookupMessages {
  @override String prefixAgo() => '';
  @override String prefixFromNow() => '';
  @override String suffixAgo() => '';
  @override String suffixFromNow() => '';
  @override String lessThanOneMinute(int seconds) => 'today';
  @override String aboutAMinute(int minutes) => 'today';
  @override String minutes(int minutes) => 'today';
  @override String aboutAnHour(int minutes) => 'today';
  @override String hours(int hours) => 'today';
  @override String aDay(int hours) => 'today';
  @override String days(int days) => '${days}d';
  @override String aboutAMonth(int days) => '${days}d';
  @override String months(int months) => '${months}mo';
  @override String aboutAYear(int year) => '${year}y';
  @override String years(int years) => '${years}y';
  @override String wordSeparator() => ' ';
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AppCubit(),
      child: MaterialApp(
        title: 'Smart Attendance',
        theme: ThemeData(colorSchemeSeed: const Color(0xff101826)),
        home: const MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {


  final PersistentTabController _controller = PersistentTabController(initialIndex: 0);

  List<Widget> _buildScreens() {
    return [
      const ScanQrScreen(),
      const PersonsScreen(),
      const SizedBox()
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(CupertinoIcons.camera_viewfinder),
        title: ("Scan"),
        activeColorPrimary: const Color(0xff4277FF),
        inactiveColorPrimary: const Color(0xff6F99FC),
        activeColorSecondary: const Color(0xffFFFFFE),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(CupertinoIcons.person_2_alt),
        title: ("Persons"),
        activeColorPrimary: const Color(0xff4277FF),
        inactiveColorPrimary: const Color(0xff6F99FC),
        activeColorSecondary: const Color(0xffFFFFFE),
      ),
      PersistentBottomNavBarItem(
        icon: Column(
          children: [
            const Text(
              'Powered by',
              style: TextStyle(color: Color(0xffFFFFFE), fontSize: 7,fontWeight: FontWeight.bold),
            ),
            Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(7),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black
              ),
              child: const Image(image: AssetImage(Assets.assetsComindeLogo),fit: BoxFit.contain,)
            ),
          ],
        ),
        /*activeColorPrimary: const Color(0xff4277FF),
        inactiveColorPrimary: const Color(0xff6F99FC),
        activeColorSecondary: const Color(0xffFFFFFE),*/
        onPressed: (context) => launchUrl(Uri.parse('https://cominde.onrender.com')),
        onSelectedTabPressWhenNoScreensPushed: () => launchUrl(Uri.parse('https://cominde.onrender.com')),
        contentPadding: 0
      ),
    ];
  }

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final RegExp dateRegExp = RegExp(r'^\d{2}-\d{2}-\d{4}$');

  String? _validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    // Check if the input matches dd-mm-yyyy format
    if (!dateRegExp.hasMatch(value)) {
      return 'Enter date in dd-mm-yyyy format';
    }

    final parts = value.split('-');
    final day = int.tryParse(parts[0]) ?? 0;
    final month = int.tryParse(parts[1]) ?? 0;
    final year = int.tryParse(parts[2]) ?? 0;

    if (day < 1 || day > 31) {
      return 'Invalid day';
    }
    if (month < 1 || month > 12) {
      return 'Invalid month';
    }
    if (year < 1900 || year > DateTime.now().year) {
      return 'Invalid year';
    }

    return null;
  }

  String _autoFormatDate(String value, bool isBackspace) {
    // Remove any non-digit characters from the input
    value = value.replaceAll(RegExp(r'\D'), '');

    // Apply formatting based on length
    if (value.length >= 2) {
      value = '${value.substring(0, 2)}-${value.substring(2)}';
    }
    if (value.length >= 5) {
      value = '${value.substring(0, 5)}-${value.substring(5)}';
    }

    // If backspace is pressed and there's a trailing hyphen, remove it
    if (isBackspace && value.endsWith('-')) {
      value = value.substring(0, value.length - 1);
    }

    // Limit the length to 10 characters (dd-mm-yyyy)
    if (value.length > 10) {
      value = value.substring(0, 10);
    }
    return value;
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool loading = false;

  DateTime? convertToDateTime(String input) {
    // Check if the input matches the dd-mm-yyyy format using RegExp
    final RegExp dateRegExp = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$');
    final match = dateRegExp.firstMatch(input);

    if (match != null) {
      // Extract day, month, and year from the input
      final day = int.tryParse(match.group(1)!);
      final month = int.tryParse(match.group(2)!);
      final year = int.tryParse(match.group(3)!);

      if (day != null && month != null && year != null) {
        // Create a DateTime object from the extracted values
        return DateTime(year, month, day);
      }
    }
    return null; // Return null if the input is invalid
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
      backgroundColor: const Color(0xff1F2936),
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
        padding: const EdgeInsets.all(0),
        backgroundColor: const Color(0xff101826),
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
        navBarHeight: kBottomNavigationBarHeight+25,
        navBarStyle: NavBarStyle.style7,
        floatingActionButton: _controller.index==1?Padding(
          padding: const EdgeInsets.all(8.0),
          child: FloatingActionButton(
            onPressed: (){
              showDialog(context: context, builder: (context) => StatefulBuilder(
                builder: (context, innerSetState) {
                  return Material(
                    child: Container(
                      color: const Color(0xff1F2936),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
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
                                              color: const Color(0xff4277FF),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xff4277FF).withOpacity(0.75),
                                                  blurRadius: 8,
                                                ),
                                              ],
                                            ),
                                            padding: const EdgeInsets.all(12),
                                            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xffFFFFFE),),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Add New One',
                                    style: TextStyle(color: const Color(0xffFFFFFE), fontSize: 22, fontWeight: FontWeight.bold, shadows: [BoxShadow(color: const Color(0xffFFFFFE).withOpacity(0.75), blurRadius: 4,)]),
                                  ),
                                  const Expanded(
                                    child: SizedBox(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32,),
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Color(0xff4277FF))
                                  ),
                                  hintText: 'Name',
                                  focusColor: const Color(0xff4277FF),
                                  hintStyle: TextStyle(
                                    color: const Color(0xffFFFFFE).withOpacity(0.75),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                style: const TextStyle(
                                  color: Color(0xffFFFFFE),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                ),
                                keyboardType: TextInputType.name,
                                validator: (value) {
                                  if(value == null || value.isEmpty) {
                                    return 'Must Enter Name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8,),
                              TextFormField(
                                controller: _birthDateController,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xff4277FF)),
                                  ),
                                  hintText: 'Birth Date (dd-mm-yyyy)',
                                  focusColor: const Color(0xff4277FF),
                                  hintStyle: TextStyle(
                                    color: const Color(0xffFFFFFE).withOpacity(0.75),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                style: const TextStyle(
                                  color: Color(0xffFFFFFE),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10), // Limit input to 10 digits
                                  TextInputFormatter.withFunction((oldValue, newValue) {
                                    final isBackspace = oldValue.text.length > newValue.text.length;

                                    // Call auto-formatting function with the backspace flag
                                    final formattedValue = _autoFormatDate(newValue.text, isBackspace);

                                    return TextEditingValue(
                                      text: formattedValue,
                                      selection: TextSelection.collapsed(offset: formattedValue.length),
                                    );
                                  }),
                                ],
                                validator: _validateDate,
                              ),
                              const SizedBox(height: 8,),
                              TextFormField(
                                controller: _addressController,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Color(0xff4277FF))
                                  ),
                                  hintText: 'Address',
                                  focusColor: const Color(0xff4277FF),
                                  hintStyle: TextStyle(
                                    color: const Color(0xffFFFFFE).withOpacity(0.75),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                style: const TextStyle(
                                  color: Color(0xffFFFFFE),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                ),
                                keyboardType: TextInputType.streetAddress,
                              ),
                              const SizedBox(height: 8,),
                              TextFormField(
                                controller: _phoneController,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Color(0xff4277FF))
                                  ),
                                  hintText: 'Phone',
                                  focusColor: const Color(0xff4277FF),
                                  hintStyle: TextStyle(
                                    color: const Color(0xffFFFFFE).withOpacity(0.75),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                style: const TextStyle(
                                  color: Color(0xffFFFFFE),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                              const Expanded(child: SizedBox()),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: GestureDetector(
                                  onTap: () async {
                                    if (_formKey.currentState!.validate() && !loading) {
                                      innerSetState(() {
                                        loading = true;
                                      });
                                      final supabase = Supabase.instance.client;
                                      await supabase
                                          .from('people')
                                          .insert(Person(name: _nameController.text, address: _addressController.text, birthDate: convertToDateTime(_birthDateController.text)).toJsonWithoutID());
                                      final data = await supabase
                                          .from('people')
                                          .select()
                                          .order('created_at', ascending: false)
                                          .limit(1);
                                      _addressController.clear();
                                      _birthDateController.clear();
                                      _nameController.clear();
                                      _formKey.currentState!.reset();
                                      innerSetState(() {
                                        loading = false;
                                      });
                                      if(context.mounted) {
                                        context.read<AppCubit>().setState(() {
                                          for (var element in data) {
                                            context.read<AppCubit>().persons.add(Person.fromJson(element));
                                          }
                                        });
                                        Navigator.pop(context);
                                      }
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: const Color(0xff4277FF),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xff4277FF).withOpacity(0.75),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: loading? const CircularProgressIndicator(color: Color(0xffFFFFFE),) : Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Add',
                                          style: TextStyle(color: const Color(0xffFFFFFE), fontSize: 22, fontWeight: FontWeight.bold, shadows: [BoxShadow(color: const Color(0xffFFFFFE).withOpacity(0.75), blurRadius: 4,)]),
                                        ),
                                        const SizedBox(width: 64,),
                                        Icon(
                                          Icons.done_outline_rounded,
                                          color: const Color(0xffFFFFFE),
                                          shadows: [
                                            BoxShadow(
                                              color: const Color(0xffFFFFFE).withOpacity(0.75),
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
                    ),
                  );
                }
              ),);
            },
            backgroundColor: const Color(0xff101826),
            child: Icon(
              Icons.add_rounded,
              color: const Color(0xffFFFFFE),
              shadows: [
                BoxShadow(
                  color: const Color(0xffFFFFFE).withOpacity(0.75),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ):null,
        decoration: const NavBarDecoration(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
          colorBehindNavBar: Color(0xff1F2936),
        ),
      ),
    );
  }
}