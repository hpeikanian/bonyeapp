import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'core/api.dart';
import 'core/widgets.dart';
import 'screens/login.dart';
import 'screens/home.dart';
import 'screens/pets.dart';
import 'screens/club.dart';
import 'screens/content.dart';
import 'screens/account.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'pet.bonye.customer.audio',
    androidNotificationChannelName: 'پادکست‌های بنیه',
    androidNotificationOngoing: true,
    androidNotificationIcon: 'drawable/bonye_icon',
  );
  final api = BonyeApi();
  await api.restore();
  runApp(BonyeApp(api: api));
}

class BonyeApp extends StatefulWidget {
  final BonyeApi api;
  const BonyeApp({super.key, required this.api});
  @override
  State<BonyeApp> createState() => _BonyeAppState();
}

class _BonyeAppState extends State<BonyeApp> {
  final navigator = GlobalKey<NavigatorState>();
  late bool wasSignedIn;
  BonyeApi get api => widget.api;
  @override
  void initState() {
    super.initState();
    wasSignedIn = api.signedIn;
    api.addListener(sessionChanged);
  }

  void sessionChanged() {
    if (wasSignedIn && !api.signedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          navigator.currentState?.popUntil((route) => route.isFirst);
        }
      });
    }
    wasSignedIn = api.signedIn;
  }

  @override
  void dispose() {
    api.removeListener(sessionChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        navigatorKey: navigator,
        title: 'بنیه | همراه پت شما',
        debugShowCheckedModeBanner: false,
        locale: const Locale('fa'),
        supportedLocales: const [Locale('fa')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme:
              ColorScheme.fromSeed(seedColor: brand, secondary: accent),
          scaffoldBackgroundColor: const Color(0xFFF7F6F2),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFF7F6F2),
            foregroundColor: brand,
            centerTitle: false,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(minimumSize: const Size(48, 52)),
          ),
        ),
        home: ListenableBuilder(
          listenable: api,
          builder: (context, child) => api.signedIn
              ? CustomerShell(key: const ValueKey('customer'), api: api)
              : LoginPage(api: api),
        ),
      );
}

class CustomerShell extends StatefulWidget {
  final BonyeApi api;
  const CustomerShell({super.key, required this.api});
  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int selected = 0;
  @override
  Widget build(BuildContext context) {
    final api = widget.api;
    final pages = [
      HomePage(api: api, onPets: () => setState(() => selected = 1)),
      PetsPage(api: api),
      ClubPage(api: api),
      ContentPage(api: api),
      AccountPage(api: api),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('bonYe!  |  بنیه'),
        actions: [
          IconButton(
            tooltip: 'محصولات',
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () => push(context, ProductsPage(api: api)),
          ),
        ],
      ),
      body: KeyedSubtree(key: ValueKey(selected), child: pages[selected]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (i) => setState(() => selected = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'خانه',
          ),
          NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            label: 'پت‌های من',
          ),
          NavigationDestination(
            icon: Icon(Icons.stars_outlined),
            label: 'باشگاه',
          ),
          NavigationDestination(
            icon: Icon(Icons.headphones_outlined),
            label: 'آموزش',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'حساب من',
          ),
        ],
      ),
    );
  }
}
