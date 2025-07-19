import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/app_viewmodel.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _yandexTokenController;
  late TextEditingController _userNameController;

  @override
  void initState() {
    super.initState();
    final viewModel = Provider.of<AppViewModel>(context, listen: false);

    _yandexTokenController = TextEditingController(text: viewModel.yandexToken);
    _userNameController = TextEditingController(text: viewModel.userName);
  }

  @override
  void dispose() {
    _yandexTokenController.dispose();
    _userNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Настройки')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Ваше имя (для имени файла отчета)',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _userNameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Иван Иванов',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Токен Яндекс.Диска', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              TextField(
                controller: _yandexTokenController,
                obscureText: true, // Скрываем токен для безопасности
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'OAuth токен',
                ),
              ),
              const Spacer(), // Занимает все свободное место, прижимая кнопку к низу
              ElevatedButton(
                onPressed: () {
                  final viewModel = Provider.of<AppViewModel>(context, listen: false);

                  viewModel.saveSettings(
                    _yandexTokenController.text.trim(),
                    _userNameController.text.trim(),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Настройки сохранены')),
                  );

                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Сохранить', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}