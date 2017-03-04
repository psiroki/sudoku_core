typedef Iterable<int> _PositionEnumerator(int base);

Iterable<int> _rowIndices(int base) sync* {
  base -= base % 9;
  for (int i = 0; i < 9; ++i) yield base + i;
}

Iterable<int> _columnIndices(int base) sync* {
  int offset = base % 9;
  for (int i = 0; i < 9; ++i) {
    yield offset;
    offset += 9;
  }
}

Iterable<int> _cellIndices(int base) sync* {
  int cellLineStart = base - base % 27;
  int offset = base % 9;
  offset = cellLineStart + offset - offset % 3;
  for (int i = 0; i < 3; ++i) {
    for (int j = 0; j < 3; ++j) {
      yield offset + j;
    }
    offset += 9;
  }
}

const List<_PositionEnumerator> _POSITION_ENUMERATORS =
    const <_PositionEnumerator>[_rowIndices, _columnIndices, _cellIndices];

final List<List<int>> PEERS = new List.generate(81, (int index) {
  Set<int> neighbors = new Set();
  for (_PositionEnumerator indices in _POSITION_ENUMERATORS) {
    neighbors.addAll(indices(index));
  }
  neighbors.remove(index);
  List<int> result = neighbors.toList(growable: false);
  result.sort();
  return new List.unmodifiable(result);
});

final List<List<List<int>>> UNITS = new List.generate(
    81,
    (int index) => new List.unmodifiable(_POSITION_ENUMERATORS.map((indices) =>
        new List.unmodifiable((new Set.from(indices(index))..remove(index))
            .toList(growable: false)..sort()))));
