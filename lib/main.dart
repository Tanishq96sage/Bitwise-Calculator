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
  bool expand = false; // toggle for the extra panel

  void _onPressed(String value) {
    setState(() {
      if (value == 'AC') {
        expression = '';
        result = '';
      } else if (value == '⌫') {
        if (expression.isNotEmpty) {
          expression = expression.substring(0, expression.length - 1);
          try {
            result = expression.isEmpty ? '' : _evaluateExpression(expression);
          } catch (e) {
            result = '';
          }
        }
      } else {
        expression += value;
        try {
          result = _evaluateExpression(expression);
        } catch (e) {
          result = '';
        }
      }
    });
  }

  // Main evaluator: returns a String (either numeric string or formatted text for list/binary)
  String _evaluateExpression(String expr) {
    expr = expr.replaceAll(' ', '');
    if (expr.isEmpty) return '0';

    // Helper to determine if a string is a pure integer (optional minus)
    bool isPureInt(String s) => RegExp(r'^-?\d+$').hasMatch(s);

    // --- Process function calls repeatedly (innermost-first) ---
    // List of functions to support (we process mex/gcd/lcm/isPrime/nextPrime/prevPrime/divisors/log2/toBin)
    // For each function we find matches without nested parentheses: func\([^()]*\)
    // If a function yields a non-numeric display (divisors when requested as standalone, toBin standalone),
    // and the whole expression equals that function call, we return the formatted string immediately.
    String working = expr;

    bool replacedAny;
    do {
      replacedAny = false;

      // mex(...)
      final mexRegex = RegExp(r'mex\(([^()]*)\)');
      final mexMatch = mexRegex.firstMatch(working);
      if (mexMatch != null) {
        final inside = mexMatch.group(1)!;
        final parts = inside.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        final nums = parts.map((p) {
          final v = _evaluateExpression(p);
          return int.tryParse(v) ?? 0;
        }).toSet().toList()
          ..sort();
        int mexValue = 0;
        for (final x in nums) {
          if (x == mexValue) mexValue++;
          else if (x > mexValue) break;
        }
        working = working.replaceRange(mexMatch.start, mexMatch.end, mexValue.toString());
        replacedAny = true;
        continue;
      }

      // gcd(a,b)
      final gcdRegex = RegExp(r'gcd\(([^()]*)\)');
      final gcdMatch = gcdRegex.firstMatch(working);
      if (gcdMatch != null) {
        final inside = gcdMatch.group(1)!;
        final parts = inside.split(',').map((s) => s.trim()).toList();
        int a = 0, b = 0;
        if (parts.isNotEmpty) a = int.tryParse(_evaluateExpression(parts[0])) ?? 0;
        if (parts.length > 1) b = int.tryParse(_evaluateExpression(parts[1])) ?? 0;
        int g = _gcd(a.abs(), b.abs());
        working = working.replaceRange(gcdMatch.start, gcdMatch.end, g.toString());
        replacedAny = true;
        continue;
      }

      // lcm(a,b)
      final lcmRegex = RegExp(r'lcm\(([^()]*)\)');
      final lcmMatch = lcmRegex.firstMatch(working);
      if (lcmMatch != null) {
        final inside = lcmMatch.group(1)!;
        final parts = inside.split(',').map((s) => s.trim()).toList();
        int a = 0, b = 0;
        if (parts.isNotEmpty) a = int.tryParse(_evaluateExpression(parts[0])) ?? 0;
        if (parts.length > 1) b = int.tryParse(_evaluateExpression(parts[1])) ?? 0;
        int l = 0;
        if (a == 0 || b == 0) {
          l = 0;
        } else {
          l = (a.abs() ~/ _gcd(a.abs(), b.abs())) * b.abs();
        }
        working = working.replaceRange(lcmMatch.start, lcmMatch.end, l.toString());
        replacedAny = true;
        continue;
      }

      // isPrime(x)
      final isPrimeRegex = RegExp(r'isPrime\(([^()]*)\)');
      final isPrimeMatch = isPrimeRegex.firstMatch(working);
      if (isPrimeMatch != null) {
        final inside = isPrimeMatch.group(1)!;
        final valStr = _evaluateExpression(inside);
        final n = int.tryParse(valStr) ?? 0;
        final res = _isPrime(n) ? 1 : 0;
        working = working.replaceRange(isPrimeMatch.start, isPrimeMatch.end, res.toString());
        replacedAny = true;
        continue;
      }

      // nextPrime(x)
      final nextPrimeRegex = RegExp(r'nextPrime\(([^()]*)\)');
      final nextPrimeMatch = nextPrimeRegex.firstMatch(working);
      if (nextPrimeMatch != null) {
        final inside = nextPrimeMatch.group(1)!;
        final valStr = _evaluateExpression(inside);
        int n = int.tryParse(valStr) ?? 0;
        int candidate = n < 2 ? 2 : n + 1;
        while (!_isPrime(candidate)) candidate++;
        working = working.replaceRange(nextPrimeMatch.start, nextPrimeMatch.end, candidate.toString());
        replacedAny = true;
        continue;
      }

      // prevPrime(x)
      final prevPrimeRegex = RegExp(r'prevPrime\(([^()]*)\)');
      final prevPrimeMatch = prevPrimeRegex.firstMatch(working);
      if (prevPrimeMatch != null) {
        final inside = prevPrimeMatch.group(1)!;
        final valStr = _evaluateExpression(inside);
        int n = int.tryParse(valStr) ?? 0;
        String replacement;
        if (n <= 0 || n == 1) {
          replacement = '0';
        } else if (n == 2) {
          replacement = '2';
        } else {
          int candidate = n - 1;
          while (candidate >= 2 && !_isPrime(candidate)) candidate--;
          if (candidate >= 2) replacement = candidate.toString(); else replacement = '0';
        }
        working = working.replaceRange(prevPrimeMatch.start, prevPrimeMatch.end, replacement);
        replacedAny = true;
        continue;
      }

      // divisors(x)
      final divisorsRegex = RegExp(r'divisors\(([^()]*)\)');
      final divisorsMatch = divisorsRegex.firstMatch(working);
      if (divisorsMatch != null) {
        final inside = divisorsMatch.group(1)!;
        final valStr = _evaluateExpression(inside);
        final n = int.tryParse(valStr) ?? 0;
        if (n <= 0) {
          // if used standalone, return formatted string; else replace with 0 (count)
          if (working == divisorsMatch.group(0)) {
            return '0 divisors: []';
          } else {
            working = working.replaceRange(divisorsMatch.start, divisorsMatch.end, '0');
            replacedAny = true;
            continue;
          }
        }
        final list = _divisorsOf(n);
        final display = '${list.length} divisors: [${list.join(',')}]';
        if (working == divisorsMatch.group(0)) {
          // whole expression is divisors(...): return formatted text
          return display;
        } else {
          // replace with the count so arithmetic can continue
          working = working.replaceRange(divisorsMatch.start, divisorsMatch.end, list.length.toString());
          replacedAny = true;
          continue;
        }
      }

      // log2(x) -> floor(log2(x))
      final log2Regex = RegExp(r'log2\(([^()]*)\)');
      final log2Match = log2Regex.firstMatch(working);
      if (log2Match != null) {
        final inside = log2Match.group(1)!;
        final valStr = _evaluateExpression(inside);
        final n = int.tryParse(valStr) ?? 0;
        int r = 0;
        if (n > 0) r = (log(n) / log(2)).floor();
        working = working.replaceRange(log2Match.start, log2Match.end, r.toString());
        replacedAny = true;
        continue;
      }

      // toBin(x) -> convert to binary; if standalone return 'binary: <bits>', else replace with decimal value
      final toBinRegex = RegExp(r'toBin\(([^()]*)\)');
      final toBinMatch = toBinRegex.firstMatch(working);
      if (toBinMatch != null) {
        final inside = toBinMatch.group(1)!;
        final valStr = _evaluateExpression(inside);
        final n = int.tryParse(valStr) ?? 0;
        final bits = n >= 0 ? n.toRadixString(2) : '-' + (n.abs()).toRadixString(2);
        if (working == toBinMatch.group(0)) {
          return 'binary: $bits';
        } else {
          // replace with decimal number (so expression keeps numeric form)
          working = working.replaceRange(toBinMatch.start, toBinMatch.end, n.toString());
          replacedAny = true;
          continue;
        }
      }
    } while (replacedAny);

    // At this point there are no supported function calls left.
    // If working contains any non-numeric display markers (starts with 'binary:' or 'divisors:'), return it
    if (working.startsWith('binary:') || working.contains('divisors:')) {
      return working;
    }

    // --- Now evaluate the remaining expression with bitwise ops ^ & | and % ---
    // Tokenization (similar to your original approach)
    final tokens = <String>[];
    final buffer = StringBuffer();

    for (int i = 0; i < working.length; i++) {
      final c = working[i];
      if ('^&|%'.contains(c)) {
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

    if (tokens.isEmpty) return '0';

    // Validate first token is integer
    if (!isPureInt(tokens[0])) {
      // malformed -> return empty
      return '';
    }

    BigInt acc = BigInt.parse(tokens[0]);
    for (int i = 1; i < tokens.length - 1; i += 2) {
      final op = tokens[i];
      final nextToken = tokens[i + 1];
      if (!isPureInt(nextToken)) {
        return '';
      }
      final next = BigInt.parse(nextToken);
      if (op == '^') {
        acc = acc ^ next;
      } else if (op == '&') {
        acc = acc & next;
      } else if (op == '|') {
        acc = acc | next;
      } else if (op == '%') {
        if (next == BigInt.zero) {
          return 'ERR: div by 0';
        }
        acc = acc % next;
      }
    }

    return acc.toString();
  }

  // ---------- helper methods ----------

  int _gcd(int a, int b) {
    a = a.abs();
    b = b.abs();
    while (b != 0) {
      final t = b;
      b = a % b;
      a = t;
    }
    return a;
  }

  bool _isPrime(int n) {
    if (n <= 1) return false;
    if (n <= 3) return true;
    if (n % 2 == 0) return n == 2;
    final r = sqrt(n).toInt();
    for (int i = 3; i <= r; i += 2) {
      if (n % i == 0) return false;
    }
    return true;
  }

  List<int> _divisorsOf(int n) {
    final s = <int>{};
    final lim = sqrt(n).toInt();
    for (int i = 1; i <= lim; i++) {
      if (n % i == 0) {
        s.add(i);
        s.add(n ~/ i);
      }
    }
    final list = s.toList()..sort();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final buttons = [
      ['AC', '&', '|', '^'],
      ['7', '8', '9', '%'],
      ['4', '5', '6', 'mex('],
      ['1', '2', '3', ','],
      ['0', '(', ')', '⌫'],
    ];

    final extraButtonsRow1 = ['gcd(', 'lcm(', 'isPrime(', 'nextPrime('];
    final extraButtonsRow2 = ['prevPrime(', 'divisors(', 'log2(', 'toBin('];

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

            // Expand/collapse arrow
            GestureDetector(
              onTap: () => setState(() => expand = !expand),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Icon(
                  expand ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                  size: 32,
                  color: Colors.white70,
                ),
              ),
            ),

            // Expanded scientific panel (2 rows)
            if (expand)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Column(
                  children: [
                    // Row 1
                    SizedBox(
                      height: 64,
                      child: Row(
                        children: extraButtonsRow1.map((text) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurpleAccent.withOpacity(0.8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                onPressed: () => _onPressed(text),
                                child: Text(text, style: const TextStyle(fontSize: 18)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    // Row 2
                    SizedBox(
                      height: 64,
                      child: Row(
                        children: extraButtonsRow2.map((text) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurpleAccent.withOpacity(0.8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                onPressed: () => _onPressed(text),
                                child: Text(text, style: const TextStyle(fontSize: 18)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
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
                          final isOperator =
                          ['&', '|', '^', '%', 'mex(', ',', '(', ')', 'AC', '⌫']
                              .contains(text);
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
                                      fontSize: 22,
                                      fontWeight: FontWeight.w500,
                                      color: isOperator ? Colors.white : Colors.grey[200],
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
