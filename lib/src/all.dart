// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../boolean_selector.dart';

/// A selector that matches all inputs.
class All implements BooleanSelector {
  // TODO(nweiz): Stop explicitly providing a type argument when sdk#32412 is
  // fixed.
  final variables = const <String>[];

  const All();

  bool evaluate(semantics) => true;

  BooleanSelector intersection(BooleanSelector other) => other;

  BooleanSelector union(BooleanSelector other) => this;

  void validate(bool Function(String variable) isDefined) {}

  String toString() => "<all>";
}
