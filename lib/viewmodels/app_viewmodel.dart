import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/box.dart';
import '../models/specification_item.dart';

class AppViewModel extends ChangeNotifier {
  // --- СОСТОЯНИЕ ---
  List<SpecificationItem> _fullItemList =
      []; // Полный список всех единиц товара
  List<GroupedArticle> _groupedArticles =
      []; // Сгруппированный список для экрана сортировки
  List<Box> _boxes = [];
  int _currentBoxIndex = 0;
  String _uploadUrl = '';
  bool _isLoading = false;
  String _errorMessage = '';

  // --- ГЕТТЕРЫ ---
  List<GroupedArticle> get groupedArticles => _groupedArticles;
  List<Box> get boxes => _boxes;
  Box get currentBox => _boxes[_currentBoxIndex];
  String get uploadUrl => _uploadUrl;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isDataLoaded => _fullItemList.isNotEmpty;

  AppViewModel() {
    loadSettings();
  }

  // --- МЕТОДЫ ---

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = '';
  }

  // 1. Загрузка Excel файла
  Future<void> loadExcelFile() async {
    _setLoading(true);
    _clearError();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null) {
        final path = result.files.single.path!;
        final bytes = File(path).readAsBytesSync();
        final excel = Excel.decodeBytes(bytes);
        final sheet = excel.tables[excel.tables.keys.first]!;

        final items = <SpecificationItem>[];
        final grouped = <String, int>{};

        // Начинаем с 9-й строки (индекс 8), пропуская шапку
        for (var i = 8; i < sheet.maxRows; i++) {
          final row = sheet.row(i);
          // Индексы колонок: C=2 (Артикул), D=3 (Наименование), M=12 (Кол-во)
          final article = row[2]?.value?.toString().trim() ?? '';
          final name = row[3]?.value?.toString().trim() ?? '';
          final quantity = int.tryParse(row[9]?.value?.toString() ?? '0') ?? 0;
          print(article + name + quantity.toString());

          if (article.isNotEmpty && quantity > 0) {
            for (int j = 0; j < quantity; j++) {
              items.add(
                SpecificationItem(
                  article: article,
                  name: name,
                  id: j.toString(),
                ),
              );
            }
            grouped.update(
              article,
              (value) => value + quantity,
              ifAbsent: () => quantity,
            );
          }
        }

        if (items.isEmpty) {
          _errorMessage = "В файле не найдено товаров с количеством > 0.";
        } else {
          _fullItemList = items;
          _groupedArticles = grouped.entries
              .map(
                (e) => GroupedArticle(article: e.key, totalQuantity: e.value),
              )
              .toList();
          _boxes = [Box(name: 'Ящик 1', items: {})];
          _currentBoxIndex = 0;
        }
      }
    } catch (e) {
      _errorMessage = "Ошибка при чтении файла: $e";
      print(_errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  // 2. Логика для экрана сортировки
  void updateItemCountInCurrentBox(String article, int newCount) {
    if (newCount < 0) return;

    // TODO: Можно добавить логику проверки, чтобы не превышать общее кол-во
    currentBox.items[article] = newCount;
    // Удаляем из карты, если количество 0, для чистоты
    if (newCount == 0) {
      currentBox.items.remove(article);
    }
    notifyListeners();
  }

  void addNewBox() {
    final newBoxName = 'Ящик ${_boxes.length + 1}';
    _boxes.add(Box(name: newBoxName, items: {}));
    _currentBoxIndex = _boxes.length - 1; // Переключаемся на новый ящик
    notifyListeners();
  }

  void selectBox(int index) {
    _currentBoxIndex = index;
    notifyListeners();
  }

  // 3. Генерация PDF отчета
  Future<void> generateReport() async {
    _setLoading(true);
    try {
      final pdf = pw.Document();
      final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
      final ttf = pw.Font.ttf(fontData);

      final headerStyle = pw.TextStyle(
        font: ttf,
        fontSize: 11,
        fontWeight: pw.FontWeight.bold,
      );
      final cellStyle = pw.TextStyle(font: ttf, fontSize: 10);

      for (final box in _boxes) {
        // Пропускаем пустые ящики
        if (box.items.isEmpty) continue;

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Отчет',
                    style: pw.TextStyle(font: ttf, fontSize: 18),
                  ),
                  pw.Divider(),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Дата: ${DateFormat('dd.MM.yyyy').format(DateTime.now())}',
                        style: cellStyle,
                      ),
                      pw.Text(
                        'Заказчик: ...',
                        style: cellStyle,
                      ), // Можно добавить в UI для ввода
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '№ ящика (реализация): ${box.name}',
                        style: cellStyle,
                      ),
                      pw.Text('№ спецификации: ...', style: cellStyle),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.Table(
                    border: pw.TableBorder.all(),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(1),
                      1: const pw.FlexColumnWidth(4),
                      2: const pw.FlexColumnWidth(2),
                    },
                    children: [
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text('№ п/п', style: headerStyle),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              'Артикул изделия',
                              style: headerStyle,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text('Количество', style: headerStyle),
                          ),
                        ],
                      ),
                      ...box.items.entries
                          .where((entry) => entry.value > 0)
                          .toList()
                          .asMap()
                          .entries
                          .map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            return pw.TableRow(
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(4),
                                  child: pw.Text(
                                    (index + 1).toString(),
                                    style: cellStyle,
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(4),
                                  child: pw.Text(item.key, style: cellStyle),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(4),
                                  child: pw.Text(
                                    item.value.toString(),
                                    style: cellStyle,
                                  ),
                                ),
                              ],
                            );
                          }),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      }

      final output = await getApplicationDocumentsDirectory();
      final file = File(
        "${output.path}/report_${DateTime.now().millisecondsSinceEpoch}.pdf",
      );
      print(file.path);
      await file.writeAsBytes(await pdf.save());

      // await OpenFile.open(file.path);
    } catch (e) {
      _errorMessage = "Ошибка при создании PDF: $e";
      print(_errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  // 4. Настройки
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _uploadUrl = prefs.getString('uploadUrl') ?? 'https://yadi.sk/d/...';
    notifyListeners();
  }

  Future<void> saveSettings(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uploadUrl', url);
    _uploadUrl = url;
    notifyListeners();
  }
}
