import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

class YamlReader{
  final String filename;
  List<dynamic> _categories = [];

  YamlReader({required this.filename}){
    _initializeReader(filename);
  }

  Future<void> _initializeReader(String filename) async{
    try {
      String yamlString = await rootBundle.loadString(filename);
      var yamlMap = await loadYaml(yamlString) as YamlMap;
      for (var keys in yamlMap.keys){
        _categories.add(yamlMap[keys]);
      }
    }
    catch (_){
      print("Error loading file");
    }

  }


  List<dynamic> getCategories(){
    return _categories;
  }

}