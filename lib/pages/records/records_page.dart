import 'package:flutter/material.dart';

/// 日记列表页（备用，当前日记通过首页时间线访问）
class RecordsPage extends StatelessWidget {
  const RecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('旅行日记')),
      body: const Center(
        child: Text('请通过首页时间线浏览日记'),
      ),
    );
  }
}
