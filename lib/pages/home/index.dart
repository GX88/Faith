import 'package:faith/router/index.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('首页'), elevation: 0),
      body: Center(
        child: Column(
          children: [
            const Text('首页'),
            ElevatedButton(
              onPressed: () => RouteHelper.push(RoutePath.profile),
              child: const Text('跳转'),
            ),
          ],
        ),
      ),
    );
  }
}
