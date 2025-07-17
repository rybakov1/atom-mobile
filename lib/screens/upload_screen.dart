import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/app_viewmodel.dart';

class UploadScreen extends StatelessWidget {
  const UploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Загрузка артикула'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ],
        ),
        body: Consumer<AppViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Выбрать файл'),
                    onPressed: () async {
                      await viewModel.loadExcelFile();
                      if (viewModel.errorMessage.isNotEmpty &&
                          context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(viewModel.errorMessage)),
                        );
                      }
                    },
                  ),
                  const Spacer(),
                  ElevatedButton(
                    child: const Text('Продолжить'),
                    onPressed: viewModel.isDataLoaded
                        ? () => Navigator.pushNamed(context, '/sort')
                        : null,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
