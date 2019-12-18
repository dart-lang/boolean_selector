// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'package:boolean_selector/src/ast.dart';
import 'package:boolean_selector/src/parser.dart';

/// A matcher that asserts that a value is a [ConditionalNode].
final _isConditionalNode = TypeMatcher<ConditionalNode>();

/// A matcher that asserts that a value is an [OrNode].
final _isOrNode = TypeMatcher<OrNode>();

/// A matcher that asserts that a value is an [AndNode].
final _isAndNode = TypeMatcher<AndNode>();

/// A matcher that asserts that a value is a [NotNode].
final _isNotNode = TypeMatcher<NotNode>();

void main() {
  group('parses a conditional expression', () {
    test('with identifiers', () {
      var node = _parse('  a ? b : c   ');
      expect(node.toString(), equals('a ? b : c'));

      expect(node.span.text, equals('a ? b : c'));
      expect(node.span.start.offset, equals(2));
      expect(node.span.end.offset, equals(11));
    });

    test('with nested ors', () {
      // Should parse as "(a || b) ? (c || d) : (e || f)".
      // Should not parse as "a || (b ? (c || d) : (e || f))".
      // Should not parse as "((a || b) ? (c || d) : e) || f".
      // Should not parse as "a || (b ? (c || d) : e) || f".
      _expectToString('a || b ? c || d : e || f', 'a || b ? c || d : e || f');
    });

    test('with a conditional expression as branch 1', () {
      // Should parse as "a ? (b ? c : d) : e".
      var node = _parse('a ? b ? c : d : e');
      expect(node, _isConditionalNode);
      expect(node.condition, _isVar('a'));
      expect(node.whenFalse, _isVar('e'));

      expect(node.whenTrue, _isConditionalNode);
      expect(node.whenTrue.condition, _isVar('b'));
      expect(node.whenTrue.whenTrue, _isVar('c'));
      expect(node.whenTrue.whenFalse, _isVar('d'));
    });

    test('with a conditional expression as branch 2', () {
      // Should parse as "a ? b : (c ? d : e)".
      // Should not parse as "(a ? b : c) ? d : e".
      var node = _parse('a ? b : c ? d : e');
      expect(node, _isConditionalNode);
      expect(node.condition, _isVar('a'));
      expect(node.whenTrue, _isVar('b'));

      expect(node.whenFalse, _isConditionalNode);
      expect(node.whenFalse.condition, _isVar('c'));
      expect(node.whenFalse.whenTrue, _isVar('d'));
      expect(node.whenFalse.whenFalse, _isVar('e'));
    });

    group('which must have', () {
      test('an expression after the ?', () {
        expect(() => _parse('a ?'), throwsFormatException);
        expect(() => _parse('a ? && b'), throwsFormatException);
      });

      test('a :', () {
        expect(() => _parse('a ? b'), throwsFormatException);
        expect(() => _parse('a ? b && c'), throwsFormatException);
      });

      test('an expression after the :', () {
        expect(() => _parse('a ? b :'), throwsFormatException);
        expect(() => _parse('a ? b : && c'), throwsFormatException);
      });
    });
  });

  group('parses an or expression', () {
    test('with identifiers', () {
      var node = _parse('  a || b   ');
      expect(node, _isOrNode);
      expect(node.left, _isVar('a'));
      expect(node.right, _isVar('b'));

      expect(node.span.text, equals('a || b'));
      expect(node.span.start.offset, equals(2));
      expect(node.span.end.offset, equals(8));
    });

    test('with nested ands', () {
      // Should parse as "(a && b) || (c && d)".
      // Should not parse as "a && (b || c) && d".
      var node = _parse('a && b || c && d');
      expect(node, _isOrNode);

      expect(node.left, _isAndNode);
      expect(node.left.left, _isVar('a'));
      expect(node.left.right, _isVar('b'));

      expect(node.right, _isAndNode);
      expect(node.right.left, _isVar('c'));
      expect(node.right.right, _isVar('d'));
    });

    test('with trailing ors', () {
      // Should parse as "a || (b || (c || d))", although it doesn't affect the
      // semantics.
      var node = _parse('a || b || c || d');

      for (var variable in ['a', 'b', 'c']) {
        expect(node, _isOrNode);
        expect(node.left, _isVar(variable));
        node = node.right;
      }
      expect(node, _isVar('d'));
    });

    test('which must have an expression after the ||', () {
      expect(() => _parse('a ||'), throwsFormatException);
      expect(() => _parse('a || && b'), throwsFormatException);
    });
  });

  group('parses an and expression', () {
    test('with identifiers', () {
      var node = _parse('  a && b   ');
      expect(node, _isAndNode);
      expect(node.left, _isVar('a'));
      expect(node.right, _isVar('b'));

      expect(node.span.text, equals('a && b'));
      expect(node.span.start.offset, equals(2));
      expect(node.span.end.offset, equals(8));
    });

    test('with nested nots', () {
      // Should parse as "(!a) && (!b)", obviously.
      // Should not parse as "!(a && (!b))".
      var node = _parse('!a && !b');
      expect(node, _isAndNode);

      expect(node.left, _isNotNode);
      expect(node.left.child, _isVar('a'));

      expect(node.right, _isNotNode);
      expect(node.right.child, _isVar('b'));
    });

    test('with trailing ands', () {
      // Should parse as "a && (b && (c && d))", although it doesn't affect the
      // semantics since .
      var node = _parse('a && b && c && d');

      for (var variable in ['a', 'b', 'c']) {
        expect(node, _isAndNode);
        expect(node.left, _isVar(variable));
        node = node.right;
      }
      expect(node, _isVar('d'));
    });

    test('which must have an expression after the &&', () {
      expect(() => _parse('a &&'), throwsFormatException);
      expect(() => _parse('a && && b'), throwsFormatException);
    });
  });

  group('parses a not expression', () {
    test('with an identifier', () {
      var node = _parse('  ! a    ');
      expect(node, _isNotNode);
      expect(node.child, _isVar('a'));

      expect(node.span.text, equals('! a'));
      expect(node.span.start.offset, equals(2));
      expect(node.span.end.offset, equals(5));
    });

    test('with a parenthesized expression', () {
      var node = _parse('!(a || b)');
      expect(node, _isNotNode);

      expect(node.child, _isOrNode);
      expect(node.child.left, _isVar('a'));
      expect(node.child.right, _isVar('b'));
    });

    test('with a nested not', () {
      var node = _parse('!!a');
      expect(node, _isNotNode);
      expect(node.child, _isNotNode);
      expect(node.child.child, _isVar('a'));
    });

    test('which must have an expression after the !', () {
      expect(() => _parse('!'), throwsFormatException);
      expect(() => _parse('! && a'), throwsFormatException);
    });
  });

  group('parses a parenthesized expression', () {
    test('with an identifier', () {
      var node = _parse('(a)');
      expect(node, _isVar('a'));
    });

    test('controls precedence', () {
      // Without parentheses, this would parse as "(a || b) ? c : d".
      var node = _parse('a || (b ? c : d)');

      expect(node, _isOrNode);
      expect(node.left, _isVar('a'));

      expect(node.right, _isConditionalNode);
      expect(node.right.condition, _isVar('b'));
      expect(node.right.whenTrue, _isVar('c'));
      expect(node.right.whenFalse, _isVar('d'));
    });

    group('which must have', () {
      test('an expression within the ()', () {
        expect(() => _parse('()'), throwsFormatException);
        expect(() => _parse('( && a )'), throwsFormatException);
      });

      test('a matching )', () {
        expect(() => _parse('( a'), throwsFormatException);
      });
    });
  });

  group('disallows', () {
    test('an empty selector', () {
      expect(() => _parse(''), throwsFormatException);
    });

    test('too many expressions', () {
      expect(() => _parse('a b'), throwsFormatException);
    });
  });
}

/// Parses [selector] and returns its root node.
dynamic _parse(String selector) => Parser(selector).parse();

/// A matcher that asserts that a value is a [VariableNode] with the given
/// [name].
Matcher _isVar(String name) => predicate(
    (value) => value is VariableNode && value.name == name,
    'is a variable named "$name"');

void _expectToString(String selector, [String result]) {
  result ??= selector;
  expect(_toString(selector), equals(result),
      reason: 'Expected toString of "$selector" to be "$result".');
}

String _toString(String selector) => Parser(selector).parse().toString();
