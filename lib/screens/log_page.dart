import 'package:flutter/material.dart';
import 'package:grain/app_logger.dart';

class LogPage extends StatelessWidget {
  const LogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final logs = InMemoryLogOutput.logs.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Theme.of(context).dividerColor, height: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              InMemoryLogOutput.clear();
              (context as Element).markNeedsBuild();
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: logs.length,
        itemBuilder: (_, index) => Padding(
          padding: const EdgeInsets.all(4.0),
          child: Text(logs[index]),
        ),
      ),
    );
  }
}
