// Package imports:
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

// Project imports:
import '../../models/nap/anno/nap_anno_content_model.dart';
import '../../models/nap/anno/nap_anno_list_model.dart';
import '../../request/nap/nap_api_anno.dart';
import '../../ui/sp_infobar.dart';
import '../../widgets/nap/nap_anno_card.dart';

/// 公告页面
class NapAnnoPage extends StatefulWidget {
  /// 构造函数
  const NapAnnoPage({super.key});

  @override
  State<NapAnnoPage> createState() => _NapAnnoPageState();
}

/// 公告页面状态
class _NapAnnoPageState extends State<NapAnnoPage>
    with AutomaticKeepAliveClientMixin {
  /// 公告列表
  List<NapAnnoListModel> annoList = [];

  /// 公告内容列表
  List<NapAnnoContentModel> annoContentList = [];

  /// t
  String t = '';

  /// api
  final SprNapApiAnno api = SprNapApiAnno();

  /// tabIndex
  int currentIndex = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await loadAnnoList();
    });
  }

  /// 加载公告列表
  Future<void> loadAnnoList() async {
    annoList.clear();
    annoContentList.clear();
    if (mounted) setState(() {});
    var listResp = await api.getAnnoList();
    if (listResp.retcode != 0) {
      if (mounted) await SpInfobar.bbs(context, listResp);
      return;
    }
    var listData = listResp.data as NapAnnoListModelData;
    annoList = listData.list.map((e) => e.list).expand((e) => e).toList();
    t = listData.t;
    var contentResp = await api.getAnnoContent(t);
    if (contentResp.retcode != 0) {
      if (mounted) await SpInfobar.bbs(context, contentResp);
      return;
    }
    var contentData = contentResp.data as NapAnnoContentModelData;
    annoContentList = contentData.list;
    if (mounted) setState(() {});
    if (mounted) await SpInfobar.success(context, '公告加载成功');
  }

  /// 获取标题
  String getTitle(String title) {
    var reg = RegExp(r'<[^>]*>');
    if (reg.hasMatch(title)) {
      return title.replaceAll(reg, '');
    }
    return title;
  }

  /// 显示公告
  VoidCallback showAnno(BuildContext context, NapAnnoContentModel content) {
    return () {
      showDialog(
        barrierDismissible: true,
        dismissWithEsc: true,
        context: context,
        builder: (context) {
          return ContentDialog(
            constraints: BoxConstraints(
              maxHeight: 480.h,
              maxWidth: 800.w,
              minHeight: 120.h,
              minWidth: 240.w,
            ),
            title: Text(getTitle(content.title)),
            content: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: 8.w,
                vertical: 8.h,
              ),
              child: HtmlWidget(
                content.content,
                textStyle: const TextStyle(fontFamily: 'SarasaGothic'),
              ),
            ),
            actions: [
              Button(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('关闭'),
              ),
            ],
          );
        },
      );
    };
  }

  /// 构建头部
  Widget buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Row(
        children: [
          Text('公告', style: FluentTheme.of(context).typography.title),
          SizedBox(width: 8.w),
          Button(
            onPressed: () async {
              await loadAnnoList();
            },
            child: const Icon(FluentIcons.refresh),
          ),
        ],
      ),
    );
  }

  /// 构建列表
  Widget buildList(List<NapAnnoListModel> list, BuildContext context) {
    if (list.isEmpty) {
      return const Center(child: ProgressRing());
    }
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      itemCount: list.length,
      itemBuilder: (context, index) {
        var anno = list[index];
        var content = annoContentList.firstWhere(
          (element) => element.annId == anno.annId,
        );
        return NapAnnoCardWidget(
          anno: anno,
          onPressed: showAnno(context, content),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ScaffoldPage(
      header: buildHeader(context),
      content: TabView(
        currentIndex: currentIndex,
        closeButtonVisibility: CloseButtonVisibilityMode.never,
        tabWidthBehavior: TabWidthBehavior.sizeToContent,
        tabs: [
          Tab(
            icon: currentIndex == 0 ? const Icon(FluentIcons.game) : null,
            text: const Text('游戏公告'),
            body: buildList(
              annoList.where((e) => e.type == 3).toList(),
              context,
            ),
            selectedBackgroundColor: FluentTheme.of(context).accentColor,
          ),
          Tab(
            icon: currentIndex == 1 ? const Icon(FluentIcons.calendar) : null,
            text: const Text('活动公告'),
            body: buildList(
              annoList.where((e) => e.type == 4).toList(),
              context,
            ),
            selectedBackgroundColor: FluentTheme.of(context).accentColor,
          ),
        ],
        onChanged: (index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
    );
  }
}
