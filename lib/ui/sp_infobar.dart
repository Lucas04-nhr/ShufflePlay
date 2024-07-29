// Package imports:
import 'package:fluent_ui/fluent_ui.dart';

/// 对SnackBar的封装
class SpInfobar {
  SpInfobar._();

  /// 实例
  static final SpInfobar _instance = SpInfobar._();

  /// 获取实例
  factory SpInfobar() => _instance;

  /// show
  static Future<void> show(
    BuildContext context,
    String text,
    InfoBarSeverity severity,
  ) async {
    return await displayInfoBar(context, builder: (context, close) {
      return InfoBar(title: Text(text), severity: severity);
    });
  }

  /// info
  static Future<void> info(BuildContext context, String text) async {
    return await show(context, text, InfoBarSeverity.info);
  }

  /// success
  static Future<void> success(BuildContext context, String text) async {
    return await show(context, text, InfoBarSeverity.success);
  }

  /// warning
  static Future<void> warn(BuildContext context, String text) async {
    return await show(context, text, InfoBarSeverity.warning);
  }

  /// error
  static Future<void> error(BuildContext context, String text) async {
    return await show(context, text, InfoBarSeverity.error);
  }
}
