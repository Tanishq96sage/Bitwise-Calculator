import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const BitwiseCalculatorApp());
}

class BitwiseCalculatorApp extends StatelessWidget {
  const BitwiseCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bitwise Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurpleAccent,
          brightness: Brightness.dark,
        ),
      ),
      home: const BitwiseCalculator(),
    );
  }
}

class BitwiseCalculator extends StatefulWidget {
  const BitwiseCalculator({super.key});

  @override
  State<BitwiseCalculator> createState() => _BitwiseCalculatorState();
}

class _BitwiseCalculatorState extends State<BitwiseCalculator> {
  String expression = '';
  String result = '';

  void _onPressed(String value) {
    setState(() {
      if (value == 'AC') {
        expression = '';
        result = '';
      } else if (value == '⌫') {
        if (expression.isNotEmpty) {
          expression = expression.substring(0, expression.length - 1);
          try {
            result = expression.isEmpty ? '' : _evaluateExpression(expression).toString();
          } catch (e) {
            result = '';
          }
        }
      } else {
        expression += value;
        try {
          result = _evaluateExpression(expression).toString();
        } catch (e) {
          result = '';
        }
      }
    });
  }

  BigInt _evaluateExpression(String expr) {
    expr = expr.replaceAll(' ', '');
    if (expr.isEmpty) return BigInt.zero;

    final tokens = <String>[];
    final buffer = StringBuffer();
    for (int i = 0; i < expr.length; i++) {
      final c = expr[i];
      if ('^&|'.contains(c)) {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
          buffer.clear();
        }
        tokens.add(c);
      } else {
        buffer.write(c);
      }
    }
    if (buffer.isNotEmpty) tokens.add(buffer.toString());

    BigInt result = BigInt.parse(tokens[0]);
    for (int i = 1; i < tokens.length - 1; i += 2) {
      final op = tokens[i];
      final next = BigInt.parse(tokens[i + 1]);
      if (op == '^') {
        result = result ^ next;
      } else if (op == '&') {
        result = result & next;
      } else if (op == '|') {
        result = result | next;
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final buttons = [
      ['AC', '&', '|', '^'],
      ['7', '8', '9'],
      ['4', '5', '6'],
      ['1', '2', '3'],
      ['0', '⌫']
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Display area
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E1E1E), Color(0xFF181818)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Text(
                        expression,
                        style: const TextStyle(
                          fontSize: 36,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: result.length > 15 ? 28 : 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      child: Text(result),
                    ),
                  ],
                ),
              ),
            ),

            // Buttons area
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFF0D0D0D),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: buttons.map((row) {
                    return Expanded(
                      child: Row(
                        children: row.map((text) {
                          final isOperator = ['&', '|', '^', 'AC', '⌫'].contains(text);
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isOperator
                                      ? Colors.deepPurpleAccent.withOpacity(0.8)
                                      : Colors.grey[850],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 2,
                                ),
                                onPressed: () => _onPressed(text),
                                child: Center(
                                  child: Text(
                                    text,
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w500,
                                      color: isOperator
                                          ? Colors.white
                                          : Colors.grey[200],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
