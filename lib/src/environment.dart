import "package:sudoku_core/src/loupe.dart";

abstract class SolveEnvironment {
  void dump({
    SudokuLoupe loupe,
    List<int> highlights,
    String tableClass,
  });
  void print(dynamic obj);
}

class DummyEnvironment implements SolveEnvironment {
  @override
  void dump({
    SudokuLoupe loupe,
    List<int> highlights,
    String tableClass,
  }) {}

  @override
  void print(dynamic obj) {}
}
