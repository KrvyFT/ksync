import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/background/sync_scheduler.dart';
import 'core/di/injection.dart';
import 'presentation/blocs/sync_bloc.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/settings_page.dart';
import 'presentation/pages/sync_history_page.dart';

void main() async {
  // 确保 Flutter 环境已准备好
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 初始化所有依赖项 (Hive, SharedPreferences, Repositories, etc.)
  await configureDependencies();

  // 2. 等待所有异步单例准备就绪
  await getIt.allReady();

  // 3. 初始化后台任务
  await SyncScheduler.initialize();

  // 4. 运行应用
  runApp(const WebDavSyncApp());
}

class WebDavSyncApp extends StatelessWidget {
  const WebDavSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SyncBloc>(
          create: (context) => SyncBloc()..add(const LoadSyncSettings()),
        ),
      ],
      child: MaterialApp(
        title: 'WebDAV 同步工具',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
          ),
        ),
        themeMode: ThemeMode.system,
        home: const HomePage(),
        routes: {
          '/settings': (context) => const SettingsPage(),
          '/history': (context) => const SyncHistoryPage(),
        },
      ),
    );
  }
}
