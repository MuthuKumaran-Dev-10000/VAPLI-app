import 'package:flutter/foundation.dart';
import 'dashboard_alerts_display_model.dart';

class DashboardAlertsSyncService {
  static Future<List<AlertFolderGroup>> syncAndGetFolders(
      List<DashboardAlertDisplayItem> liveActiveAlerts) async {
    return _calculateFolders(liveActiveAlerts);
  }

  static Future<List<AlertFolderGroup>> syncAndGetCompletedFolders(
      List<DashboardAlertDisplayItem> liveCompletedAlerts) async {
    return _calculateFolders(liveCompletedAlerts);
  }

  static String _cleanParamLabel(String label) {
    var l = label.trim();
    if (l.startsWith('.')) {
      l = l.substring(1).trim();
    }
    if (l.isEmpty || l.toLowerCase() == 'general' || l == '.') {
      return 'System Alert';
    }
    return l;
  }

  static String _cleanAssetName(String name, String code, String id) {
    final n = name.trim();
    if (n.isEmpty || n.toLowerCase() == 'unknown asset' || n == '.') {
      return 'Asset ${code.trim().isNotEmpty ? code.trim() : id}';
    }
    return n;
  }

  static String _cleanAlertTitle(String title, String message) {
    var t = title.trim();
    if (t.isEmpty) {
      t = message.trim();
    }
    if (t.isEmpty) {
      return 'General Alert';
    }
    return t;
  }

  static List<AlertFolderGroup> _calculateFolders(
      List<DashboardAlertDisplayItem> alerts) {
    if (alerts.isEmpty) return [];

    final Map<String, List<DashboardAlertDisplayItem>> paramGroups = {};
    for (final a in alerts) {
      final label = _cleanParamLabel(a.paramLabel);
      paramGroups.putIfAbsent(label, () => []).add(a);
    }

    final List<AlertFolderGroup> folderGroups = [];

    for (final entry in paramGroups.entries) {
      final paramName = entry.key;
      final paramAlerts = entry.value;

      // Level 2: Group by Alert Title
      final Map<String, List<DashboardAlertDisplayItem>> titleMap = {};
      for (final a in paramAlerts) {
        final title = _cleanAlertTitle(a.alertTitle, a.message);
        titleMap.putIfAbsent(title, () => []).add(a);
      }

      final List<AlertTitleGroup> titleGroups = [];
      final Set<String> distinctTankIds = {};

      for (final titleEntry in titleMap.entries) {
        final titleName = titleEntry.key;
        final titleAlerts = titleEntry.value;

        // Level 3: Group by Asset (Template / Tank)
        final Map<String, List<DashboardAlertDisplayItem>> assetGroups = {};
        for (final a in titleAlerts) {
          distinctTankIds.add(a.tankId);
          assetGroups.putIfAbsent(a.tankId, () => []).add(a);
        }

        final List<AssetFolderGroup> assets = [];
        for (final assetEntry in assetGroups.entries) {
          final firstAlert = assetEntry.value.first;
          final assetAlerts = assetEntry.value;

          assetAlerts.sort((a, b) {
            final rankCompare = b.rankScore.compareTo(a.rankScore);
            if (rankCompare != 0) return rankCompare;
            return b.timestamp.compareTo(a.timestamp);
          });

          final cleanedAssetName = _cleanAssetName(
            firstAlert.tankName,
            firstAlert.tankCode,
            firstAlert.tankId,
          );

          assets.add(AssetFolderGroup(
            tankId: assetEntry.key,
            tankName: cleanedAssetName,
            tankCode: firstAlert.tankCode,
            alerts: assetAlerts,
            alertCount: assetAlerts.length,
          ));
        }

        assets.sort((a, b) {
          final aMaxRank = _getGroupMaxRank(a.alerts);
          final bMaxRank = _getGroupMaxRank(b.alerts);
          final rankCompare = bMaxRank.compareTo(aMaxRank);
          if (rankCompare != 0) return rankCompare;

          final aLatest = _getLatestTimestamp(a.alerts);
          final bLatest = _getLatestTimestamp(b.alerts);
          return bLatest.compareTo(aLatest);
        });

        titleGroups.add(AlertTitleGroup(
          alertTitle: titleName,
          assets: assets,
          totalAlerts: titleAlerts.length,
        ));
      }

      titleGroups.sort((a, b) => b.totalAlerts.compareTo(a.totalAlerts));
      final allParamAssets = titleGroups.expand((tg) => tg.assets).toList();

      folderGroups.add(AlertFolderGroup(
        paramLabel: paramName,
        titleGroups: titleGroups,
        assets: allParamAssets,
        totalAlerts: paramAlerts.length,
        totalAssets: distinctTankIds.length,
      ));
    }

    folderGroups.sort((a, b) {
      final aAllAlerts = a.assets.expand((asset) => asset.alerts).toList();
      final bAllAlerts = b.assets.expand((asset) => asset.alerts).toList();

      final aMaxRank = _getGroupMaxRank(aAllAlerts);
      final bMaxRank = _getGroupMaxRank(bAllAlerts);
      final rankCompare = bMaxRank.compareTo(aMaxRank);
      if (rankCompare != 0) return rankCompare;

      final aLatest = _getLatestTimestamp(aAllAlerts);
      final bLatest = _getLatestTimestamp(bAllAlerts);
      return bLatest.compareTo(aLatest);
    });

    return folderGroups;
  }

  static int _getGroupMaxRank(List<DashboardAlertDisplayItem> alerts) {
    if (alerts.isEmpty) return 0;
    int maxRank = 0;
    for (final a in alerts) {
      if (a.rankScore > maxRank) {
        maxRank = a.rankScore;
      }
    }
    return maxRank;
  }

  static String _getLatestTimestamp(List<DashboardAlertDisplayItem> alerts) {
    if (alerts.isEmpty) return '';
    String latest = '';
    for (final a in alerts) {
      if (a.timestamp.compareTo(latest) > 0) {
        latest = a.timestamp;
      }
    }
    return latest;
  }
}
