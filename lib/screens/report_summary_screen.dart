import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/app_viewmodel.dart';

class ReportSummaryScreen extends StatelessWidget {
  const ReportSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AppViewModel>(context);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Отправить отчет')),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: viewModel.boxes.length,
                    itemBuilder: (context, index) {
                      final box = viewModel.boxes[index];
                      if (box.items.isEmpty) {
                        // Не отображаем пустые ящики в итоговом отчете
                        return const SizedBox.shrink();
                      }
                      return Card(
                        color: const Color(0xFF2C2C2E),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    box.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      // Возвращаемся на экран сортировки для этого ящика
                                      viewModel.selectBox(index);
                                      Navigator.pop(
                                        context,
                                      ); // Возвращаемся с экрана отчета на экран сортировки
                                    },
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.white24, height: 20),
                              ...box.items.entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4.0,
                                  ),
                                  child: Text(
                                    'Артикул ${entry.key}   ${entry.value} шт.',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Кнопка для добавления нового ящика прямо из отчета
                      OutlinedButton(
                        onPressed: () {
                          viewModel.addNewBox();
                          Navigator.pop(context); // Возврат на экран сортировки
                        },
                        child: const Icon(Icons.add_box_outlined),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A84FF),
                          ),
                          onPressed: () async {
                            await viewModel.generateReport();
                            if (viewModel.errorMessage.isNotEmpty &&
                                context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(viewModel.errorMessage)),
                              );
                            }
                          },
                          child: const Text('Отправить в бухгалтерию'),
                        ),
                      ),
                    ],
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
  }
}
