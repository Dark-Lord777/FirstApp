import 'dart:convert';
import 'package:flutter/services.dart';

class IconCatalogService {
  static const String _catalogPath = 'assets/bee_dynamic_launcher/catalog.json';
  
  static Future<Map<String, String>> getIconDisplayNames() async {
    final String jsonString = await rootBundle.loadString(_catalogPath);
    final Map<String, dynamic> data = json.decode(jsonString);
    final Map<String, String> result = {};
    
    final List<dynamic> variants = data['variants'];
    for (var variant in variants) {
      final String id = variant['id'];
      final String displayName = variant['displayName'] ?? id;
      result[id] = displayName;
    }
    
    return result;
  }
  
  static Future<List<Map<String, dynamic>>> getIconVariants() async {
    final String jsonString = await rootBundle.loadString(_catalogPath);
    final Map<String, dynamic> data = json.decode(jsonString);
    return List<Map<String, dynamic>>.from(data['variants']);
  }
}
