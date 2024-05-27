import 'package:flutter/material.dart';

class MainScaffold extends StatelessWidget {
  final String title;
  final String currentPage;
  final VoidCallback onSettingsPressed;
  final VoidCallback? onBackPressed;
  final Widget? body;
  final Widget? floatingActionButton;

  const MainScaffold({super.key,
    required this.title,
    required this.currentPage,
    required this.onSettingsPressed,
    this.onBackPressed,
    this.body,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _getAppBar(context, title, currentPage),
      resizeToAvoidBottomInset: false,
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }

  AppBar _getAppBar(BuildContext context, String title, String currentPage) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: Text(title),
      actions: currentPage == "Settings" ? [] : [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: onSettingsPressed,
        ),
      ],
      leading: onBackPressed != null ? IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBackPressed,
      ) : null,
    );
  }
}
