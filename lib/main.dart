// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:system_theme/system_theme.dart';
import 'package:window_manager/window_manager.dart';

// Project imports:
import 'app.dart';
import 'database/sp_sqlite.dart';
import 'tools/log_tool.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await Window.initialize();
  await SystemTheme.accentColor.load();

  /// 初始化配置
  await SPLogTool().init();
  await SPSqlite().init();

  runApp(const ProviderScope(child: SPApp()));
  await Window.setEffect(effect: WindowEffect.acrylic);
}
