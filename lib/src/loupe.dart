import "dart:typed_data";

abstract class SudokuLoupeMixin {
  int get rawValue;
  set rawValue(int newValue);

  bool get isSet => value != 0;
  int get value => rawValue & 15;
  set value(int value) {
    rawValue = value & 15;
  }

  bool get hasSingleCandidate => singleCandidate != 0;
  int get singleCandidate => _singleValues[rawValue & ~15] ?? 0;
  set singleCandidate(int c) {
    rawValue = (16 << (c - 1)) | (rawValue & 15);
  }

  bool get hasAnyCandidates => (rawValue & (~15)) > 0;
  bool hasCandidate(int c) => (rawValue & (16 << (c - 1))) > 0;
  void addCandidate(int c) {
    rawValue |= 16 << (c - 1);
  }

  void removeCandidate(int c) {
    rawValue &= ~(16 << (c - 1));
  }

  void toggleCandidate(int c, [bool value]) {
    if (value != null && hasCandidate(c) == value) return;
    if (value == null) rawValue ^= 16 << (c - 1);
  }

  Iterable<int> get candidates sync* {
    int bitOffset = 0;
    int value = rawValue;
    while (true) {
      while (bitOffset < 9 && (value & (16 << bitOffset)) == 0) {
        ++bitOffset;
      }
      if (bitOffset >= 9) break;
      yield ++bitOffset;
    }
  }

  bool get solvable => isSet || hasAnyCandidates;
  bool get solved => isSet || hasSingleCandidate;
  int get solvedValue => isSet ? value : singleCandidate;

  static final Map<int, int> _singleValues = new Map.fromIterable(
      new List.generate(9, (int i) => i + 1),
      key: (int i) => 16 << (i - 1));
}

class SingleValueSudokuLoupe extends SudokuLoupeMixin {
  int rawValue;
}

class SudokuLoupe extends SudokuLoupeMixin {
  SudokuLoupe(this.backing);

  int get rawValue => backing[index];
  set rawValue(int value) {
    backing[index] = value;
  }

  Iterable<SudokuLoupe> get cells sync* {
    for (int i = 0, l = backing.length; i < l; ++i) {
      index = i;
      yield this;
    }
  }

  SudokuLoupe operator [](int i) => this..index = i;

  final Uint32List backing;
  int index;
}
