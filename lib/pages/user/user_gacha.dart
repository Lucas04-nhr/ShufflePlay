// Dart imports:
import 'dart:convert';

// Package imports:
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:json_schema/json_schema.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

// Project imports:
import '../../database/nap/nap_item_map.dart';
import '../../database/user/user_gacha.dart';
import '../../models/plugins/UIGF/uigf_model.dart';
import '../../request/plugins/hakushi_client.dart';
import '../../tools/file_tool.dart';
import '../../ui/sp_dialog.dart';
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

  /// uid列表
  List<String> uidList = [];

  /// 当前uid
  String? curUid;

  /// NapItemMap 数据库
  final sqliteMap = SpsNapItemMap();

  /// Hakushi客户端
  final hakushiApi = SprPluginHakushi();

  /// 用户祈愿数据库
  final sqliteUser = SpsUserGacha();

  /// 文件工具
  final fileTool = SPFileTool();

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
    uidList = await sqliteUser.getAllUid();
    if (uidList.isNotEmpty) {
      curUid = uidList.first;
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> importUigf4Json(BuildContext context) async {
    var filePath = await fileTool.selectFile(context: context);
    if (filePath == null) {
      if (context.mounted) await SpInfobar.warn(context, '未选择文件');
      return;
    }
    var file = await fileTool.readFile(filePath);
    if (file == null) {
      if (context.mounted) await SpInfobar.error(context, '文件读取失败');
      return;
    }
    var fileJson = jsonDecode(file);
    var result = schema.validate(fileJson);
    if (!result.isValid) {
      var error = result.errors.first;
      if (context.mounted) {
        await SpInfobar.error(context, error.message);
      }
      return;
    }
    var data = UigfModelFull.fromJson(fileJson);
    await sqliteUser.importUigf(data);
    await refreshData();
    if (context.mounted) {
      await SpInfobar.success(context, '导入成功');
    }
  }

  Future<void> exportUigf4Json(BuildContext context) async {
    var check = await SpDialog.confirm(context, '是否导出当前UID数据？', 'UID: $curUid');
    if (check == null || !check) return;
    var data = await sqliteUser.exportUigf(uids: [curUid!]);
    var downloadPath = await getDownloadsDirectory();
    if (!context.mounted || downloadPath == null) {
      if (context.mounted) await SpInfobar.error(context, '导出失败');
      return;
    }
    var dirPath = await fileTool.selectDir(context: context);
    if (dirPath == null) {
      if (context.mounted) await SpInfobar.warn(context, '未选择目录');
      return;
    }
    var fileName = 'uigf_${DateTime.now().millisecondsSinceEpoch}.json';
    var filePath = path.join(dirPath, fileName);
    await fileTool.writeFile(filePath, jsonEncode(data));
    if (context.mounted) {
      await SpInfobar.success(context, '导出成功');
    }
  }

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
        IconButton(
          icon: const Icon(FluentIcons.database_refresh),
          onPressed: () async {
            await sqliteMap.preCheck();
            await hakushiApi.freshCharacter();
            await hakushiApi.freshWeapon();
            await hakushiApi.freshBangboo();
          },
        ),
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

  /// 构建头部
  Widget buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(width: 10.w),
          const Icon(FluentIcons.auto_enhance_on),
          SizedBox(width: 10.w),
          Text('调频记录', style: TextStyle(fontSize: 20.sp)),
          SizedBox(width: 10.w),
          buildUidSelector(context),
          const Spacer(),
          buildTopBar(context),
          SizedBox(width: 10.w),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: buildHeader(),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: UserGachaViewWidget(selectedUid: curUid)),
          ],
        ),
      ),
    );
  }
}
