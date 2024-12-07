import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/widgets/animated_rotation_widget.dart';
import 'package:flutter_hbb/common/widgets/custom_password.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/desktop/pages/connection_page.dart';
import 'package:flutter_hbb/desktop/pages/desktop_setting_page.dart';
import 'package:flutter_hbb/desktop/pages/desktop_tab_page.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/models/server_model.dart';
import 'package:flutter_hbb/plugin/ui_manager.dart';
import 'package:flutter_hbb/utils/multi_window_manager.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';
import 'package:window_size/window_size.dart' as window_size;

import '../widgets/button.dart';

Future<Widget> buildHelpCards() async {
  // 禁用版本更新提示卡片
  if (false) { // 永远不会触发更新提示
    return buildInstallCard(
        "Status",
        "There is a newer version of ${bind.mainGetAppNameSync()} ${bind.mainGetNewVersion()} available.",
        "Click to download", () async {
      final Uri url = Uri.parse('https://rustdesk.com/download');
      await launchUrl(url);
    }, closeButton: true);
  }

  // 系统错误提示卡片
  if (systemError.isNotEmpty) {
    return buildInstallCard("", systemError, "", () {});
  }

  // Windows 安装状态处理
  if (isWindows && !bind.isDisableInstallation()) {
    // 只处理未安装的情况，禁用版本较低时的升级提示
    if (!bind.mainIsInstalled()) {
      return buildInstallCard(
          "", bind.isOutgoingOnly() ? "" : "install_tip", "Install",
          () async {
        await rustDeskWinManager.closeAllSubWindows();
        bind.mainGotoInstall();
      });
    }
    // 禁用低版本升级提示逻辑
  }

  // macOS 权限设置处理
  if (isMacOS) {
    final bool isOutgoingOnly = bind.isOutgoingOnly();
    if (!(isOutgoingOnly || bind.mainIsCanScreenRecording(prompt: false))) {
      return buildInstallCard("Permissions", "config_screen", "Configure",
          () async {
        bind.mainIsCanScreenRecording(prompt: true);
        watchIsCanScreenRecording = true;
      }, help: 'Help', link: translate("doc_mac_permission"));
    } else if (!isOutgoingOnly && !bind.mainIsProcessTrusted(prompt: false)) {
      return buildInstallCard("Permissions", "config_acc", "Configure",
          () async {
        bind.mainIsProcessTrusted(prompt: true);
        watchIsProcessTrust = true;
      }, help: 'Help', link: translate("doc_mac_permission"));
    } else if (!bind.mainIsCanInputMonitoring(prompt: false)) {
      return buildInstallCard("Permissions", "config_input", "Configure",
          () async {
        bind.mainIsCanInputMonitoring(prompt: true);
        watchIsInputMonitoring = true;
      }, help: 'Help', link: translate("doc_mac_permission"));
    } else if (!isOutgoingOnly &&
        !svcStopped.value &&
        bind.mainIsInstalled() &&
        !bind.mainIsInstalledDaemon(prompt: false)) {
      return buildInstallCard("", "install_daemon_tip", "Install", () async {
        bind.mainIsInstalledDaemon(prompt: true);
      });
    }
  }

  return SizedBox.shrink(); // 默认返回空的 SizedBox
}
