import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'providers/auth_provider.dart';
import 'models/user_model.dart';
import 'core/constants/app_constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/notification_service.dart';
import 'shared/widgets/background_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase init — wrapped so it never crashes the app
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('⚠️ Firebase init failed (non-fatal): $e');
  }

  await AppConstants.init();

  // Notification init — also wrapped
  try {
    await NotificationService.init();
  } catch (e) {
    debugPrint('⚠️ Notification init failed (non-fatal): $e');
  }

  runApp(const ProviderScope(child: DocTransitApp()));
}

class NoScrollbarBehavior extends ScrollBehavior {
  const NoScrollbarBehavior();
  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class DocTransitApp extends ConsumerWidget {
  const DocTransitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Global listener for auth state to handle forced logout
    ref.listen<AsyncValue<UserModel?>>(authProvider, (previous, next) {
      final prevUser = previous?.asData?.value;
      final nextUser = next.asData?.value;
      
      if (nextUser == null && prevUser != null) {
        debugPrint('🚪 [Auth] Session invalid or logged out. Redirecting...');
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    });

    return MaterialApp(
      title: 'docTransit',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      scrollBehavior: const NoScrollbarBehavior(),
      builder: (context, child) => BackgroundWrapper(child: child!),
      home: const SplashScreen(),
    );
  }
}
