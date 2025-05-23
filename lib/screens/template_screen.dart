import 'package:flutter/material.dart';
import '../widgets/header_widgets.dart';

class TemplateScreen extends StatelessWidget {
  const TemplateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppHeaderWithMenu(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              HeaderWidget(),
              SizedBox(height: 20),
              Text(
                'This is a template screen.',
                style: TextStyle(fontSize: 18),
              ),
              // Add more widgets here as needed
            ],
          ),
        ),
      ),
    );
  }
}
