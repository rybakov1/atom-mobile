import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/app_viewmodel.dart';

class SortScreen extends StatelessWidget {
  const SortScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AppViewModel>(context);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text('Разборка: ${viewModel.currentBox.name}')),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: viewModel.groupedArticles.length,
                itemBuilder: (context, index) {
                  final article = viewModel.groupedArticles[index];
                  final currentCount =
                      viewModel.currentBox.items[article.article] ?? 0;

                  return Card(
                    color: const Color(0xFF2C2C2E),
                    margin: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 8,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            article.article,
                            style: const TextStyle(fontSize: 18),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  viewModel.updateItemCountInCurrentBox(
                                    article.article,
                                    currentCount - 1,
                                  );
                                },
                              ),
                              Text(
                                currentCount.toString(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  // Опционально: добавить проверку на максимальное количество
                                  // if (currentCount < article.totalQuantity)
                                  viewModel.updateItemCountInCurrentBox(
                                    article.article,
                                    currentCount + 1,
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/summary');
                },
                child: const Text('Сформировать отчет'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
