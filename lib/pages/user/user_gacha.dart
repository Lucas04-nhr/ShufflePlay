// Dart imports:
import 'dart:convert';

// Package imports:
import 'package:file_selector/file_selector.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:json_schema/json_schema.dart';

// Project imports:
import '../../database/user/user_gacha.dart';
import '../../models/plugins/UIGF/uigf_model.dart';
import '../../ui/sp_infobar.dart';
import '../../widgets/user/user_gacha_view.dart';

class UserGachaPage extends StatefulWidget {
  const UserGachaPage({super.key});

  @override
  State<UserGachaPage> createState() => _UserGachaPageState();
}

class _UserGachaPageState extends State<UserGachaPage> {
  /// UIGFv4 JSON Schema
  late JsonSchema schema;

  /// 用户祈愿数据库
  final sqlite = SpsUserGacha();

  /// uid列表
  List<String> uidList = [];

  /// 当前uid
  String? curUid;

  @override
  void initState() {
    super.initState();
    const schemaFile = 'lib/source/schema/uigf-4.0-schema.json';
    Future.microtask(() async {
      schema = await JsonSchema.createFromUrl(schemaFile);
      await refreshData();
    });
  }

  Future<void> refreshData() async {
    uidList = await sqlite.getAllUid();
    if (uidList.isNotEmpty) {
      curUid = uidList.first;
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> importUigf4Json(BuildContext context) async {
    const XTypeGroup fileType = XTypeGroup(label: 'json', extensions: ['json']);
    XFile? file = await openFile(acceptedTypeGroups: <XTypeGroup>[fileType]);
    if (file == null) {
      if (context.mounted) await SpInfobar.warn(context, '未选择文件');
      return;
    }
    var fileJson = jsonDecode(await file.readAsString());
    var result = schema.validate(fileJson);
    if (!result.isValid) {
      var error = result.errors.first;
      if (context.mounted) {
        await SpInfobar.error(context, error.message);
      }
      return;
    }
    if (context.mounted) {
      await SpInfobar.success(context, 'JSON文件验证通过，即将导入');
    }
    var data = UigfModelFull.fromJson(fileJson);
    await sqlite.importUigf(data);
    await refreshData();
  }

  Future<void> exportUigf4Json(BuildContext context) async {}

  Widget buildTopBar(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Button(
          onPressed: () async {
            await importUigf4Json(context);
          },
          child: const Text('导入'),
        ),
        SizedBox(width: 10.w),
        Button(
          onPressed: () async {
            await exportUigf4Json(context);
          },
          child: const Text('导出'),
        ),
        SizedBox(width: 10.w),
      ],
    );
  }

  Widget buildUidSelector(BuildContext context) {
    if (uidList.isEmpty) {
      return const Text('暂无数据');
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const Text('UID:'),
        SizedBox(width: 10.w),
        DropDownButton(
          title: Text(curUid ?? '请选择'),
          items: [
            for (var uid in uidList)
              MenuFlyoutItem(
                text: Text(uid),
                onPressed: () {
                  if (mounted) {
                    setState(() {
                      curUid = uid;
                    });
                  }
                },
              ),
          ],
        ),
        SizedBox(width: 10.w),
        Text(
          '当前时区: ${DateTime.now().timeZoneName}'
          '(UTC${DateTime.now().timeZoneOffset.inHours})',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('调频记录', style: TextStyle(fontFamily: 'SarasaGothic')),
        commandBar: buildTopBar(context),
      ),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildUidSelector(context),
            SizedBox(height: 10.h),
            Expanded(child: UserGachaViewWidget(selectedUid: curUid)),
          ],
        ),
      ),
    );
  }
}
