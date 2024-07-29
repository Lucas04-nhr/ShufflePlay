// Package imports:
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 测试页面
class AppDevPage extends ConsumerStatefulWidget {
  /// 构造函数
  const AppDevPage({super.key});

  @override
  ConsumerState<AppDevPage> createState() => _AppDevPageState();
}

/// 测试页面状态
class _AppDevPageState extends ConsumerState<AppDevPage> {
  @override
  void initState() {
    super.initState();
  }

  /// 构建测试按钮
  Widget buildTest() {
    return Button(
      onPressed: () async {},
      child: const Text('Test'),
    );
  }

  /// 构建函数
  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(title: Text('Test Page')),
      content: Center(child: buildTest()),
    );
  }
}
