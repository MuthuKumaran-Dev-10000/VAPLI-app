// lib/features/dashboard_folders/dashboard_alerts_sync_service.dart

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

  /// Locally computes the folder hierarchy: Parameter Name -> Asset (Template) -> Alerts list
  static List<AlertFolderGroup> _calculateFolders(
      List<DashboardAlertDisplayItem> alerts) {
    if (alerts.isEmpty) return [];

    // Group alerts by ParamLabel (Sanitized)
    final Map<String, List<DashboardAlertDisplayItem>> paramGroups = {};
    for (final a in alerts) {
      final label = _cleanParamLabel(a.paramLabel);
      paramGroups.putIfAbsent(label, () => []).add(a);
    }

    final List<AlertFolderGroup> folderGroups = [];

    for (final entry in paramGroups.entries) {
      final paramName = entry.key;
      final paramAlerts = entry.value;

      // Group these param alerts by Asset (tankId)
      final Map<String, List<DashboardAlertDisplayItem>> assetGroups = {};
      for (final a in paramAlerts) {
        assetGroups.putIfAbsent(a.tankId, () => []).add(a);
      }

      final List<AssetFolderGroup> assets = [];
      for (final assetEntry in assetGroups.entries) {
        final firstAlert = assetEntry.value.first;
        final assetAlerts = assetEntry.value;

        // Sort alerts within the asset folder by rankScore (descending) and then time
        assetAlerts.sort((a, b) {
          final rankCompare = b.rankScore.compareTo(a.rankScore);
          if (rankCompare != 0) return rankCompare;
          return b.timestamp.compareTo(a.timestamp); // Newest first
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

      // Sort assets by max rankScore and then latest timestamp
      assets.sort((a, b) {
        final aMaxRank = _getGroupMaxRank(a.alerts);
        final bMaxRank = _getGroupMaxRank(b.alerts);
        final rankCompare = bMaxRank.compareTo(aMaxRank);
        if (rankCompare != 0) return rankCompare;

        final aLatest = _getLatestTimestamp(a.alerts);
        final bLatest = _getLatestTimestamp(b.alerts);
        return bLatest.compareTo(aLatest);
      });

      folderGroups.add(AlertFolderGroup(
        paramLabel: paramName,
        titleGroups: const [],
        assets: assets,
        totalAlerts: paramAlerts.length,
        totalAssets: assets.length,
      ));
    }

    // Sort top-level parameter folders by max rankScore and latest timestamp
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
