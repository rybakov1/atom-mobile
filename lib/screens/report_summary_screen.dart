import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/app_viewmodel.dart';

class ReportSummaryScreen extends StatelessWidget {
  const ReportSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Используем Consumer, чтобы перерисовывать только нужную часть при изменении
    return Consumer<AppViewModel>(
      builder: (context, viewModel, child) {
        // Получаем данные для отчета прямо из ViewModel
        final shortfallData = viewModel.getShortfallData();

        return SafeArea(
          child: Scaffold(
            appBar: AppBar(title: const Text('Предпросмотр отчета')),
            body: Stack(
              children: [
                // Основное содержимое
                Column(
                  children: [
                    // Если данных для отчета нет (все собрано), показываем сообщение
                    if (shortfallData.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
                              SizedBox(height: 16),
                              Text('Все товары собраны!', style: TextStyle(fontSize: 22)),
                              Text('Отчет о недосдаче не требуется.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                            ],
                          ),
                        ),
                      )
                    else
                    // Иначе, показываем список недостающих товаров
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8.0),
                          itemCount: shortfallData.length,
                          itemBuilder: (context, index) {
                            final item = shortfallData[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Артикул: ${item['article']}',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    const Divider(height: 12),
                                    Text('Требуется по спецификации: ${item['required']} шт.'),
                                    Text('Собрано (факт): ${item['packed']} шт.'),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Не хватает: ${item['shortfall']} шт.',
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    // Кнопка отправки отчета
                    if (shortfallData.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.cloud_upload_outlined),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: const Color(0xFF0A84FF),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              final bool wasReportGenerated = await viewModel.generateAndUploadShortfallReport();

                              if (!context.mounted) return;

                              // Закрываем этот экран в любом случае
                              Navigator.pop(context);

                              if (wasReportGenerated) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Отчет о недосдаче успешно загружен!')),
                                );
                              } else {
                                // Если отчет не был сгенерирован, но ошибки нет - значит, всё было собрано
                                // (этот случай тут маловероятен, но для полноты картины)
                                if (viewModel.errorMessage.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Все товары уже собраны!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  // Если есть ошибка, показываем ее
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Ошибка: ${viewModel.errorMessage}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            label: const Text('Отправить отчет о недосдаче', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ),
                  ],
                ),

                // Оверлей загрузки
                if (viewModel.isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}