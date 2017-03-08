import "package:sudoku_core/src/loupe.dart";
import "package:sudoku_core/src/environment.dart";
import "package:sudoku_core/src/neighbors.dart";
import "dart:typed_data";

typedef List<int> Eliminator([List<int> previousPositions]);

class SudokuBoard {
  static Uint32List stringToProblemBuffer(String source) =>
      new Uint32List.fromList(source.runes
          .take(81)
          .map((int code) => code >= 0x31 && code <= 0x39 ? code - 0x30 : 0)
          .toList(growable: false));

  factory SudokuBoard.fromString(String source) =>
      new SudokuBoard(stringToProblemBuffer(source));
  factory SudokuBoard([Uint32List problemBuffer]) => problemBuffer == null
      ? new SudokuBoard._(new Uint32List(81))
      : new SudokuBoard._(problemBuffer);
  factory SudokuBoard.withBacking(Uint32List problemBuffer) =
      SudokuBoard._noReset;

  SudokuBoard._(Uint32List problemBuffer)
      : this.backing = problemBuffer,
        this.loupe = new SudokuLoupe(problemBuffer) {
    addAllCandidates();
  }

  SudokuBoard._noReset(Uint32List problemBuffer)
      : this.backing = problemBuffer,
        this.loupe = new SudokuLoupe(problemBuffer) {}

  String toString() => loupe.cells
      .map((l) => l.solved ? l.solvedValue.toString() : ".")
      .join("");

  void addAllCandidates() {
    for (int i = 0; i < backing.length; ++i) {
      loupe.index = i;
      if (!loupe.isSet) {
        for (int j = 0; j < 9; ++j) loupe.addCandidate(j + 1);
      }
    }
  }

  List<int> eliminateResolved([List<int> positions]) {
    int l = positions != null ? positions.length : backing.length;
    List<int> newSingleCandidates = [];
    for (int i = 0; i < l; ++i) {
      int pos;
      if (positions != null)
        pos = positions[i];
      else
        pos = i;
      loupe.index = pos;
      bool given = loupe.isSet;
      if (given || loupe.hasSingleCandidate) {
        int val = given ? loupe.value : loupe.singleCandidate;
        for (int index in PEERS[pos]) {
          loupe.index = index;
          if (!loupe.isSet && loupe.hasCandidate(val)) {
            loupe.removeCandidate(val);
            if (loupe.hasSingleCandidate) newSingleCandidates.add(index);
          }
        }
      }
    }
    return newSingleCandidates;
  }

  List<int> eliminateUnions([List<int> unusedPreviousPositions]) {
    int l = backing.length;
    List<int> newSingleCandidates = [];
    final collector = new SingleValueSudokuLoupe();
    for (int i = 0; i < l; ++i) {
      int pos = i;
      loupe.index = pos;
      if (!loupe.isSet && !loupe.hasSingleCandidate) {
        collector.rawValue = 0;
        for (List<int> indices in UNITS[pos]) {
          for (int index in indices) {
            loupe.index = index;
            collector.rawValue |= loupe.rawValue;
          }
          loupe.index = pos;
          collector.rawValue = loupe.rawValue & ~collector.rawValue;
          if (collector.hasSingleCandidate) {
            loupe.singleCandidate = collector.singleCandidate;
            newSingleCandidates.add(pos);
            break;
          }
        }
      }
    }
    return newSingleCandidates;
  }

  void flatten() {
    for (int i = 0, l = backing.length; i < l; ++i) {
      loupe.index = i;
      loupe.value = loupe.solvedValue;
    }
  }

  bool eliminateOptions([SolveEnvironment env]) {
    if (dumpAtLeastOnce && env != null) env.dump(loupe: loupe);

    final Map<String, Eliminator> eliminators = {
      "eliminateResolved": eliminateResolved,
      "eliminateUnions": eliminateUnions,
    };
    const List<String> eliminationOrder = const [
      "eliminateResolved",
      "eliminateUnions",
    ];
    bool anyChanged = true;
    bool solved = false;
    bool solvable = true;
    bool dumpedAtLeastOnce = false;
    while (anyChanged && !solved && solvable) {
      anyChanged = false;

      for (String eliminatorName in eliminationOrder) {
        Eliminator eliminate = eliminators[eliminatorName];
        List<int> lastUpdated = null;
        List<int> updatedCells = [];
        int iterations = 0;
        while (lastUpdated == null || lastUpdated.isNotEmpty) {
          lastUpdated = eliminate(lastUpdated);
          updatedCells.addAll(lastUpdated);
          ++iterations;
        }
        if (env != null && updatedCells.isNotEmpty)
          env.print(
              "$eliminatorName \u2a2f $iterations (cells: ${updatedCells.length})");
        if (updatedCells.isNotEmpty) {
          anyChanged = true;
          if (env != null) {
            env.dump(
                loupe: loupe,
                highlights: updatedCells,
                tableClass: eliminatorName);
          }
          dumpedAtLeastOnce = true;
        }
      }

      if (!anyChanged) {
        solved = true;
        solvable = true;
        final int l = backing.length;
        for (int i = 0; i < l; ++i) {
          loupe.index = i;
          if (!loupe.solvable) {
            solvable = false;
            break;
          }
        }

        if (dumpAtLeastOnce && !dumpedAtLeastOnce && env != null)
          env.dump(loupe: loupe);

        for (int i = 0; i < l; ++i) {
          loupe.index = i;
          if (!loupe.solved) {
            solved = false;
            break;
          }
        }
      }
    }

    _solved = solved;
    _solvable = solvable;

    return solved;
  }

  bool get solved {
    if (_solved == null) _solved = !loupe.cells.any((l) => !l.solved);
    return _solved;
  }

  bool get solvable {
    if (_solvable == null)
      _solvable = !loupe.cells.any((l) => !l.isSet && !l.hasAnyCandidates);
    return _solvable;
  }

  Iterable<int> get unsolvedCells sync* {
    for (int i = 0, l = backing.length; i < l; ++i) {
      if (!loupe[i].solved) yield i;
    }
  }

  SudokuBoard clone() =>
      new SudokuBoard._noReset(new Uint32List.fromList(backing));

  bool _solved;
  bool _solvable;
  final SudokuLoupe loupe;
  final Uint32List backing;

  static const bool dumpAtLeastOnce = false;
}
