import 'package:flutter/material.dart';
import 'package:grain/app_logger.dart';

class LogPage extends StatelessWidget {
  const LogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logs = InMemoryLogOutput.logs.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Logs', style: theme.appBarTheme.titleTextStyle),
        backgroundColor: theme.appBarTheme.backgroundColor,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: theme.dividerColor, height: 1),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: theme.iconTheme.color),
            onPressed: () {
              InMemoryLogOutput.clear();
              (context as Element).markNeedsBuild();
            },
          ),
        ],
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListView.builder(
        itemCount: logs.length,
        itemBuilder: (_, index) => Padding(
          padding: const EdgeInsets.all(4.0),
          child: Text(logs[index], style: theme.textTheme.bodyMedium),
        ),
      ),
    );
  }
}
