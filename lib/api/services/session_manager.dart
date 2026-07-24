import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../healthcare_api.dart';

class SessionManager {
  static const String _keyAuthToken = 'auth_token';
  static const String _keyParentData = 'parent_data';
  static const String _keyChildData = 'child_data';
  static const String _keyChildrenListData = 'children_list_data';

  static Future<void> saveSession({
    required String token,
    ParentProfile? parent,
    ChildProfile? child,
    List<ChildProfile>? childrenList,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (token.isNotEmpty) {
      await prefs.setString(_keyAuthToken, token);
      HealthcareApi.instance.apiClient.setAuthToken(token);
    }

    if (parent != null) {
      await prefs.setString(_keyParentData, jsonEncode(parent.toJson()));
      HealthcareApi.instance.currentParent = parent;
    }

    if (child != null) {
      await prefs.setString(_keyChildData, jsonEncode(child.toJson()));
      HealthcareApi.instance.currentChild = child;
    }

    if (childrenList != null && childrenList.isNotEmpty) {
      final listJson = childrenList.map((c) => c.toJson()).toList();
      await prefs.setString(_keyChildrenListData, jsonEncode(listJson));
      HealthcareApi.instance.childrenList = childrenList;
    }
  }

  static Future<bool> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_keyAuthToken);

      if (token == null || token.isEmpty) {
        return false;
      }

      HealthcareApi.instance.apiClient.setAuthToken(token);

      final parentStr = prefs.getString(_keyParentData);
      if (parentStr != null && parentStr.isNotEmpty) {
        try {
          final Map<String, dynamic> parentMap = jsonDecode(parentStr);
          HealthcareApi.instance.currentParent = ParentProfile.fromJson(parentMap);
        } catch (_) {}
      }

      final childStr = prefs.getString(_keyChildData);
      if (childStr != null && childStr.isNotEmpty) {
        try {
          final Map<String, dynamic> childMap = jsonDecode(childStr);
          HealthcareApi.instance.currentChild = ChildProfile.fromJson(childMap);
        } catch (_) {}
      }

      final childrenListStr = prefs.getString(_keyChildrenListData);
      if (childrenListStr != null && childrenListStr.isNotEmpty) {
        try {
          final List dynamicList = jsonDecode(childrenListStr);
          HealthcareApi.instance.childrenList = dynamicList
              .map((item) => ChildProfile.fromJson(item as Map<String, dynamic>))
              .toList();
        } catch (_) {}
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyAuthToken);
      await prefs.remove(_keyParentData);
      await prefs.remove(_keyChildData);
      await prefs.remove(_keyChildrenListData);

      HealthcareApi.instance.apiClient.setAuthToken(null);
      HealthcareApi.instance.currentParent = null;
      HealthcareApi.instance.currentChild = null;
      HealthcareApi.instance.childrenList = null;
    } catch (_) {}
  }
}
