import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/app_viewmodel.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    final viewModel = Provider.of<AppViewModel>(context, listen: false);
    _urlController = TextEditingController(text: viewModel.uploadUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
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
              const Text('Отправить на диск', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'https://yadi.sk/d/...',
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  final viewModel = Provider.of<AppViewModel>(
                    context,
                    listen: false,
                  );
                  viewModel.saveSettings(_urlController.text);
                  Navigator.pop(context);
                },
                child: const Text('Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
