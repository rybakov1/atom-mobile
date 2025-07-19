import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math'; // Импортируем для использования функции min()
import '../models/box.dart';
import '../models/specification_item.dart';

class AppViewModel extends ChangeNotifier {
  static const int _colArticle = 1;
  static const int _colQuantity = 9;
  static const int _startRow = 8;

  // --- СОСТОЯНИЕ ---
  List<GroupedArticle> _groupedArticles = [];
  List<GroupedArticle> _filteredArticles = [];
  List<Box> _boxes = [];
  int _currentBoxIndex = 0;
  String _yandexToken = '';
  bool _isLoading = false;
  String _errorMessage = '';
  String _searchQuery = '';
  String _userName = '';

  final String _yandexApiUrl = 'https://cloud-api.yandex.net/v1/disk/resources';
  final String _yandexUploadPath = 'disk:/Готовые отчеты';
  final String _yandexDownloadPath = 'disk:/Спецификации';

  // --- ГЕТТЕРЫ ---
  List<GroupedArticle> get groupedArticles =>
      _searchQuery.isEmpty ? _groupedArticles : _filteredArticles;

  List<Box> get boxes => _boxes;

  Box get currentBox => _boxes[_currentBoxIndex];

  String get yandexToken => _yandexToken;

  String get userName => _userName;

  bool get isLoading => _isLoading;

  String get errorMessage => _errorMessage;

  bool get isDataLoaded => _groupedArticles.isNotEmpty;

  bool get isEverythingPacked {
    if (!isDataLoaded) return false;
    return getShortfallData().isEmpty;
  }

  AppViewModel() {
    loadSettings();
  }

  /// Генерирует и загружает отчет о недосдаче.
  /// Возвращает `true`, если отчет был успешно загружен.
  /// Возвращает `false`, если отчет не требуется (все собрано) или произошла ошибка.
  Future<bool> generateAndUploadShortfallReport() async {
    _setLoading(true);
    _clearError();
    try {
      if (_yandexToken.isEmpty) {
        throw Exception('Токен Яндекс.Диска не указан.');
      }

      final excel = _createShortfallReport();

      if (excel == null) {
        return false;
      }

      final fileBytes = excel.save();
      if (fileBytes == null) {
        throw Exception('Не удалось сохранить Excel файл.');
      }

      final fileName =
          "Отчет_о_недосдаче_${_userName}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx";
      await _uploadFileToYandexDisk(fileBytes, '$_yandexUploadPath/$fileName');
      return true;
    } catch (e) {
      _errorMessage = "Ошибка: ${e.toString().replaceAll("Exception: ", "")}";
      debugPrint(_errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void updateItemCountInCurrentBox(String article, int newCount) {
    final specArticle = _groupedArticles.firstWhere(
      (ga) => ga.article == article,
      orElse: () => GroupedArticle(article: article, totalQuantity: 0),
    );
    final totalRequiredQuantity = specArticle.totalQuantity;

    int quantityInOtherBoxes = 0;
    for (int i = 0; i < _boxes.length; i++) {
      if (i != _currentBoxIndex) {
        quantityInOtherBoxes += _boxes[i].items[article] ?? 0;
      }
    }

    final maxAllowedForThisBox = totalRequiredQuantity - quantityInOtherBoxes;
    final checkedNewCount = newCount.clamp(0, maxAllowedForThisBox);

    if (checkedNewCount == 0) {
      currentBox.items.remove(article);
    } else {
      currentBox.items[article] = checkedNewCount;
    }
    notifyListeners();
  }

  void addNewBox() {
    final newBoxName = '${_boxes.length + 1}';
    _boxes.add(Box(name: newBoxName, items: {}));
    _currentBoxIndex = _boxes.length - 1;
    notifyListeners();
  }

  void selectBox(int index) {
    _currentBoxIndex = index;
    notifyListeners();
  }

  void searchArticles(String query) {
    _searchQuery = query;
    _filteredArticles = _groupedArticles
        .where(
          (article) =>
              article.article.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    notifyListeners();
  }

  Future<void> downloadAndLoadLatestSpecification() async {
    _setLoading(true);
    _clearError();
    try {
      if (_yandexToken.isEmpty)
        throw Exception('Токен Яндекс.Диска не указан.');
      final files = await _getYandexDiskFileList(_yandexDownloadPath);
      if (files.isEmpty)
        throw Exception(
          'В папке "$_yandexDownloadPath" на Яндекс.Диске нет файлов.',
        );

      final newestExcelFile = files
          .where(
            (file) => file['name'].toString().toLowerCase().endsWith('.xlsx'),
          )
          .reduce(
            (a, b) =>
                DateTime.parse(
                  a['created'],
                ).isAfter(DateTime.parse(b['created']))
                ? a
                : b,
          );

      final downloadUrl = await _getYandexDiskDownloadUrl(
        newestExcelFile['path'],
      );
      final fileResponse = await http.get(Uri.parse(downloadUrl));
      if (fileResponse.statusCode != 200)
        throw Exception('Ошибка скачивания файла: ${fileResponse.statusCode}');

      final excel = Excel.decodeBytes(fileResponse.bodyBytes);
      _parseSpecificationFromExcel(excel);
    } catch (e) {
      _errorMessage = "Ошибка: ${e.toString().replaceAll("Exception: ", "")}";
      debugPrint(_errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadLocalExcelFile() async {
    _setLoading(true);
    _clearError();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );
      if (result != null && result.files.single.path != null) {
        final bytes = await File(result.files.single.path!).readAsBytes();
        final excel = Excel.decodeBytes(bytes);
        _parseSpecificationFromExcel(excel);
      }
    } catch (e) {
      _errorMessage = "Ошибка при чтении локального файла: $e";
      debugPrint(_errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _yandexToken = prefs.getString('yandexToken') ?? '';
    _userName = prefs.getString('userName') ?? 'DefaultUser';
    notifyListeners();
  }

  Future<void> saveSettings(String yandexToken, String userName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('yandexToken', yandexToken);
    await prefs.setString('userName', userName);
    _yandexToken = yandexToken;
    _userName = userName;
    notifyListeners();
  }

  // --- ПРИВАТНЫЕ МЕТОДЫ-ХЕЛПЕРЫ ---

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = '';
  }

  List<Map<String, dynamic>> getShortfallData() {
    final Map<String, int> totalPacked = {};
    for (final box in _boxes) {
      for (final item in box.items.entries) {
        totalPacked.update(
          item.key,
          (value) => value + item.value,
          ifAbsent: () => item.value,
        );
      }
    }

    final List<Map<String, dynamic>> reportData = [];
    for (final specArticle in _groupedArticles) {
      final requiredQty = specArticle.totalQuantity;
      final packedQty = totalPacked[specArticle.article] ?? 0;
      final shortfall = requiredQty - packedQty;

      if (shortfall > 0) {
        reportData.add({
          'article': specArticle.article,
          'required': requiredQty,
          'packed': packedQty,
          'shortfall': shortfall,
        });
      }
    }
    return reportData;
  }

  Excel? _createShortfallReport() {
    final reportData = getShortfallData();
    if (reportData.isEmpty) return null;

    var excel = Excel.createExcel();
    Sheet sheet = excel['Недосдача'];
    excel.delete('Sheet1');

    final header = [
      TextCellValue('№ п/п'),
      TextCellValue('Артикул изделия'),
      TextCellValue('Требуется по спец.'),
      TextCellValue('Собрано (факт)'),
      TextCellValue('Не хватает'),
    ];
    sheet.appendRow(header);

    reportData.sort(
      (a, b) => (a['article'] as String).compareTo(b['article'] as String),
    );

    int rowIndex = 1;
    for (final itemData in reportData) {
      sheet.appendRow([
        IntCellValue(rowIndex++),
        TextCellValue(itemData['article']),
        IntCellValue(itemData['required']),
        IntCellValue(itemData['packed']),
        IntCellValue(itemData['shortfall']),
      ]);
    }
    return excel;
  }

  void _parseSpecificationFromExcel(Excel excel) {
    final sheet = excel.tables[excel.tables.keys.first]!;
    final grouped = <String, int>{};
    for (var i = _startRow - 1; i < sheet.maxRows; i++) {
      final row = sheet.row(i);
      if (row.isEmpty || row.length <= _colQuantity) continue;
      final article = row[_colArticle]?.value?.toString().trim() ?? '';
      final quantity =
          int.tryParse(row[_colQuantity]?.value?.toString() ?? '0') ?? 0;
      if (article.isNotEmpty && quantity > 0) {
        grouped.update(
          article,
          (value) => value + quantity,
          ifAbsent: () => quantity,
        );
      }
    }
    if (grouped.isEmpty) {
      _errorMessage = "В файле не найдено товаров с количеством > 0.";
    } else {
      _groupedArticles = grouped.entries
          .map((e) => GroupedArticle(article: e.key, totalQuantity: e.value))
          .toList();
      _filteredArticles = List.from(_groupedArticles);
      _boxes = [Box(name: 'Ящик 1', items: {})];
      _currentBoxIndex = 0;
    }
  }

  Map<String, String> get _yandexAuthHeaders => {
    'Authorization': 'OAuth $_yandexToken',
  };

  Future<List<dynamic>> _getYandexDiskFileList(String path) async {
    final response = await http.get(
      Uri.parse('$_yandexApiUrl?path=$path&sort=created'),
      headers: _yandexAuthHeaders,
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Ошибка получения списка файлов: ${jsonDecode(response.body)['message']}',
      );
    }
    return (jsonDecode(response.body)['_embedded']?['items']
            as List<dynamic>?) ??
        [];
  }

  Future<String> _getYandexDiskDownloadUrl(String path) async {
    final response = await http.get(
      Uri.parse('$_yandexApiUrl/download?path=$path'),
      headers: _yandexAuthHeaders,
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Ошибка получения ссылки на скачивание: ${jsonDecode(response.body)['message']}',
      );
    }
    return jsonDecode(response.body)['href'];
  }

  Future<void> _uploadFileToYandexDisk(
    List<int> fileBytes,
    String remotePath,
  ) async {
    final response = await http.get(
      Uri.parse('$_yandexApiUrl/upload?path=$remotePath&overwrite=true'),
      headers: _yandexAuthHeaders,
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Ошибка получения URL для загрузки на Яндекс.Диск: ${jsonDecode(response.body)['message']}',
      );
    }
    final uploadUrl = jsonDecode(response.body)['href'];

    final uploadResponse = await http.put(
      Uri.parse(uploadUrl),
      body: fileBytes,
    );

    if (uploadResponse.statusCode != 201 && uploadResponse.statusCode != 202) {
      throw Exception(
        'Ошибка загрузки файла на Яндекс.Диск. Статус: ${uploadResponse.statusCode}',
      );
    }
  }
}
