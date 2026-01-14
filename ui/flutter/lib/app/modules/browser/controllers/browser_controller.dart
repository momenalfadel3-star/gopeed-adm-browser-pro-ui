import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../api/model/create_task.dart';
import '../../../../api/model/request.dart';
import '../../../routes/app_pages.dart';

class BrowserController extends GetxController {
  final urlText = TextEditingController();
  final progress = 0.0.obs;
  final canBack = false.obs;
  final canForward = false.obs;
  final pageTitle = ''.obs;

  // UI state (ADM-like options)
  final desktopMode = false.obs;
  final blockImages = false.obs;
  final enableJs = true.obs;

  late final WebViewController web;

  final _cookies = WebViewCookieManager();

  static const String homeUrl = 'https://www.google.com/';

  static const Set<String> _downloadExts = {
    'zip',
    'apk',
    'pdf',
    'mp4',
    'mkv',
    'mp3',
    'm4a',
    'wav',
    'flac',
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    '7z',
    'rar',
    'tar',
    'gz',
    'tgz',
    'iso',
    'exe',
    'msi',
    'dmg',
    'm3u8',
    'torrent',
  };

  @override
  void onInit() {
    super.onInit();

    final initial = (Get.arguments is String && (Get.arguments as String).isNotEmpty)
        ? (Get.arguments as String)
        : homeUrl;

    urlText.text = initial;

    web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => progress.value = p / 100.0,
          onUrlChange: (c) {
            if (c.url != null) {
              urlText.text = c.url!;
            }
          },
          onPageFinished: (_) async {
            try {
              final t = await web.getTitle();
              if (t != null) pageTitle.value = t;
            } catch (_) {}
            await _updateNavState();
            await _applyContentRules();
          },
          onNavigationRequest: (req) {
            final url = req.url;
            if (_looksLikeDownload(url)) {
              _openCreate(url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..setUserAgent(_userAgent())
      ..loadRequest(Uri.parse(_normalizeUrl(initial)));
  }

  @override
  void onClose() {
    urlText.dispose();
    super.onClose();
  }

  Future<void> _updateNavState() async {
    try {
      canBack.value = await web.canGoBack();
      canForward.value = await web.canGoForward();
    } catch (_) {
      // ignore
    }
  }

  void goToInput() {
    final input = urlText.text.trim();
    if (input.isEmpty) return;
    final url = _normalizeUrl(input);
    web.loadRequest(Uri.parse(url));
  }

  void goHome() {
    urlText.text = homeUrl;
    web.loadRequest(Uri.parse(homeUrl));
  }

  Future<void> toggleDesktopMode() async {
    desktopMode.toggle();
    await web.setUserAgent(_userAgent());
    await reload();
  }

  Future<void> toggleJavaScript() async {
    enableJs.toggle();
    await web.setJavaScriptMode(enableJs.value ? JavaScriptMode.unrestricted : JavaScriptMode.disabled);
    await reload();
  }

  Future<void> toggleImages() async {
    blockImages.toggle();
    // Inject CSS to hide images (best-effort, like lightweight adblock)
    await _applyContentRules();
    await reload();
  }

  Future<void> clearBrowserData() async {
    try {
      await web.clearCache();
      await _cookies.clearCookies();
    } catch (_) {
      // ignore
    }
  }

  Future<void> copyCurrentUrl() async {
    final u = urlText.text.trim();
    if (u.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: u));
    Get.snackbar('Copied', 'Link copied to clipboard');
  }

  String _userAgent() {
    // A03s = Android Chrome UA. Desktop mode swaps to desktop UA.
    if (desktopMode.value) {
      return 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';
    }
    return 'Mozilla/5.0 (Linux; Android 13; SM-A037F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';
  }

  Future<void> _applyContentRules() async {
    if (!blockImages.value) return;
    // Hide images via CSS injection
    const js = """
      (function(){
        try {
          var style = document.getElementById('__gopeed_img_block');
          if(!style){
            style = document.createElement('style');
            style.id='__gopeed_img_block';
            style.innerHTML='img,video,source,picture{display:none !important;}';
            document.head.appendChild(style);
          }
        } catch(e) {}
      })();
    """;
    try {
      await web.runJavaScript(js);
    } catch (_) {
      // ignore
    }
  }

  Future<void> back() async {
    if (await web.canGoBack()) {
      await web.goBack();
      await _updateNavState();
    }
  }

  Future<void> forward() async {
    if (await web.canGoForward()) {
      await web.goForward();
      await _updateNavState();
    }
  }

  Future<void> reload() async {
    await web.reload();
  }

  String _normalizeUrl(String input) {
    final s = input.trim();
    if (s.startsWith('http://') || s.startsWith('https://')) return s;
    // If user typed a domain or words, search via Google.
    if (s.contains(' ') || !s.contains('.')) {
      final q = Uri.encodeComponent(s);
      return 'https://www.google.com/search?q=$q';
    }
    return 'https://$s';
  }

  bool _looksLikeDownload(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path.toLowerCase();
      final last = path.split('/').last;
      final dot = last.lastIndexOf('.');
      if (dot > 0 && dot < last.length - 1) {
        final ext = last.substring(dot + 1);
        if (_downloadExts.contains(ext)) return true;
      }

      // Common download hints
      final u = url.toLowerCase();
      if (u.contains('download=1') || u.contains('attachment') || u.contains('dl=1')) {
        return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  void _openCreate(String url) {
    final task = CreateTask(req: Request(url: url));
    Get.rootDelegate.toNamed(Routes.CREATE, arguments: task);
  }
}
