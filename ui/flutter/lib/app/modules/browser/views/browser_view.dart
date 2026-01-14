import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../controllers/browser_controller.dart';
import '../../../routes/app_pages.dart';

class BrowserView extends GetView<BrowserController> {
  const BrowserView({Key? key}) : super(key: key);

  void _openMenu(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home_rounded),
                title: const Text('Home'),
                onTap: () {
                  Get.back();
                  controller.goHome();
                },
              ),
              Obx(() => SwitchListTile(
                    value: controller.desktopMode.value,
                    onChanged: (_) => controller.toggleDesktopMode(),
                    secondary: const Icon(Icons.desktop_windows_rounded),
                    title: const Text('Desktop mode'),
                  )),
              Obx(() => SwitchListTile(
                    value: controller.enableJs.value,
                    onChanged: (_) => controller.toggleJavaScript(),
                    secondary: const Icon(Icons.javascript_rounded),
                    title: const Text('JavaScript'),
                  )),
              Obx(() => SwitchListTile(
                    value: controller.blockImages.value,
                    onChanged: (_) => controller.toggleImages(),
                    secondary: const Icon(Icons.image_not_supported_rounded),
                    title: const Text('Block images (lite)'),
                  )),
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text('Copy link'),
                onTap: () {
                  Get.back();
                  controller.copyCurrentUrl();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_sweep_rounded),
                title: const Text('Clear cache & cookies'),
                onTap: () async {
                  Get.back();
                  await controller.clearBrowserData();
                  Get.snackbar('Done', 'Browser data cleared');
                },
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: SafeArea(
          bottom: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: () => _openMenu(context),
                ),
                Expanded(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline_rounded, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: controller.urlText,
                            textInputAction: TextInputAction.go,
                            decoration: const InputDecoration(
                              hintText: 'Search or type URL',
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onSubmitted: (_) => controller.goToInput(),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.arrow_forward_rounded),
                          onPressed: controller.goToInput,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: controller.reload,
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Obx(() {
            final title = controller.pageTitle.value.trim();
            if (title.isEmpty) return const SizedBox.shrink();
            return Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
              ),
            );
          }),
          Obx(() {
            final p = controller.progress.value;
            if (p <= 0 || p >= 1) return const SizedBox(height: 2);
            return LinearProgressIndicator(value: p, minHeight: 2);
          }),
          Expanded(child: WebViewWidget(controller: controller.web)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(top: BorderSide(color: cs.outlineVariant.withOpacity(0.25))),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(() => IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: controller.canBack.value ? controller.back : null,
                  )),
              Obx(() => IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded),
                    onPressed: controller.canForward.value ? controller.forward : null,
                  )),
              IconButton(
                icon: const Icon(Icons.home_rounded),
                onPressed: controller.goHome,
              ),
              IconButton(
                icon: const Icon(Icons.download_rounded),
                onPressed: () => Get.rootDelegate.toNamed(Routes.TASK),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded),
                onPressed: () => _openMenu(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
