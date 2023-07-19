import 'dart:async';

import 'package:depot/depot.dart';
import 'package:yaml/yaml.dart';

/// [SettingsModuleFacade] - interface for SettingsModule
class SettingsModuleFacade extends Facade {
  //
  Future<String> getSettings(String keySetting);

  /// Получение всего списка настроек
  Future<Map<String, String>> getListSettings(List<String> listKeysSettings);

  /// Добавление настроек
  Future<void> addSettings(Map<String, dynamic> newSetting);

  /// Чтения конфиг-файла, для корректной работы необходимо считать конфиг-файл в **String** представлении и передать его в эту функцию
  Future<void> readConfigFile(String yamlString);

  /// Проходит по мапе конфигурационного файла, если есть подстановки в виде **$KEY**,
  /// то смотрит в переменные окружения, ищет значение по ключу **KEY** и заменяет подстановку на **VALUE**,
  /// присвоенное этому ключу
  ///
  /// **сonfig.yaml:**
  /// ```yaml
  /// port: $PORT
  /// ```
  ///
  /// **some.env:**
  /// ```env
  /// PORT=23555
  /// ```
  /// *вызов функции **getValuesFromEnv***
  ///
  /// **Результат:**
  /// ```yaml
  /// port: 23555
  /// ```
  Future<void> getValuesFromEnv(Map<String, dynamic> envMap);

  /// "Закрепляет" настройки
  void finalize();

  SettingsModuleFacade(super.mode, super.tram, super.returner);

  static String get name => 'SettingsModuleFacade';
}

/// [SettingsModule] - module for work with application settings
class SettingsModule extends Module implements SettingsModuleFacade {
  SettingsModule() {
    addCommand(#finalize, finalize);
    addCommand(#addSettings, addSettings);
    addCommand(#readConfigFile, readConfigFile);
    addCommand(#getValuesFromEnv, getValuesFromEnv);
    addRequest(#getSettings, getSettings);
    addRequest(#getListSettings, getListSettings);
  }

  @override
  // Future<void> get initialize => isFinal.future;
  Future<void> get initialize => Future.delayed(Duration(milliseconds: 50));

  Completer isFinal = Completer();

  /// [allSettings] - stores all settings
  Map<String, dynamic> allSettings = {};

  /// [addSettings] - command to add settings to the [allSettings]
  @override
  Future<void> addSettings(Map<String, dynamic> newSetting) async {
    // print('>>>> Map1 $allSettings');
    // print('>>>> newSetting:$newSetting');
    allSettings.addAll(newSetting);
    // print('>>>> Map2 $allSettings');
  }

  @override
  void finalize() async {
    // print('>>>> Finalize');
    isFinal.complete();
  }

  /// [getSettings] - request to get the setting value by key
  @override
  Future<String> getSettings(String keySetting) async {
    // final settingsCompleter = SettingsCompleter();
    await isFinal.future;
    if (allSettings.isEmpty) {
      throw BadRequestException('NOT WORKING');
      // settingsCompleter.getSettings().then((value) => allSettings.addAll(value),
      //     onError: (error) {
      //       BadRequestException(error);
      //     });
    }

    if (allSettings.containsKey(keySetting)) {
      return allSettings[keySetting] as String;
    } else {
      throw NoKeyException(keySetting);
    }
  }

  /// [getListSettings] - request to get list setting value by list key
  @override
  Future<Map<String, String>> getListSettings(List<String> listKeysSettings) {
    // TODO: implement getListSettings
    throw UnimplementedError();
  }

  @override
  Future<void> readConfigFile(String yamlString) async {
    try {
      final yamlMapData = loadYaml(yamlString);
      final mapData = convertYamlMapToMap(yamlMapData as YamlMap);
      // getValuesFromEnv(mapData);
      allSettings.addAll(mapData);
    } catch (e) {
      print('Настройки не загружены: $e');
    }
  }

  @override
  Future<void> getValuesFromEnv(Map<String, dynamic> envMap) async {
    try {
      allSettings.forEach((key, value) {
        if (value is String && value.startsWith(r"$")) {
          final envKey = value.substring(1);

          if (!envMap.containsKey(envKey)) {
            value = 'null';
          }
          allSettings[key] = envMap[envKey];
        }
      });
    } catch (e) {
      print(e);
    }
  }

  /// Конвертирует **YamlMap** в **Map<String, String>**
  Map<String, dynamic> convertYamlMapToMap(YamlMap yamlMap) {
    final map = <String, dynamic>{};

    for (final entry in yamlMap.entries) {
      if (entry.value is YamlMap || entry.value is Map) {
        map[entry.key.toString()] = convertYamlMapToMap(entry.value as YamlMap);
      } else {
        map[entry.key.toString()] = entry.value.toString();
      }
    }
    return map;
  }
}

/// [SettingsCompleter] - helper class for working with data retrieval requests
class SettingsCompleter {
  final Completer<Map<String, String>> completer = Completer();

  /// [getSettings] - get all settings method from api, files etc.
  Future<Map<String, String>> getSettings() async {
    final allSettings = <String, String>{};
    final assemblySettings = await _getAssemblySettings();
    final appSettings = await _getAppSettings();
    final accountSettings = await _getAccountSettings();
    allSettings.addAll(assemblySettings);
    allSettings.addAll(appSettings);
    allSettings.addAll(accountSettings);
    completer.complete(allSettings);
    return completer.future;
  }

  Future<Map<String, String>> _getAssemblySettings() async {
    try {
      // запрос api или файл
    } catch (error) {
      completer.completeError(error);
    }
    return <String, String>{};
  }

  Future<Map<String, String>> _getAppSettings() async {
    try {
      // запрос api или на файл
    } catch (error) {
      completer.completeError(error);
    }
    return <String, String>{};
  }

  Future<Map<String, String>> _getAccountSettings() async {
    try {
      // запрос api или на файл
    } catch (error) {
      completer.completeError(error);
    }
    return <String, String>{};
  }
}

abstract class SettingsModuleException implements Exception {
  String get message;
}

class NoKeyException extends SettingsModuleException {
  @override
  final String message;

  NoKeyException(String key) : message = 'SettingsModule error: The key:$key is not in the settings list';
}

class BadRequestException extends SettingsModuleException {
  @override
  final String message;

  BadRequestException(String error) : message = 'SettingsModule error: Something wrong with request. Error: $error';
}
