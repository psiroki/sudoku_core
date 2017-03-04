import "package:sudoku_core/src/environment.dart";
import "package:sudoku_core/src/board.dart";
import "package:sudoku_core/src/loupe.dart";
import "dart:typed_data";
import "dart:math";

abstract class Chooser {
  int chooseRandomIndex(List array);
  T chooseRandom<T>(List<T> array);
  void shuffle(List array);
}

class RandomChooser implements Chooser {
  @override
  int chooseRandomIndex(List array) => random.nextInt(array.length);

  @override
  T chooseRandom<T>(List<T> array) => array[chooseRandomIndex(array)];

  @override
  void shuffle(List array) => array.shuffle(random);

  final Random random = new Random.secure();
}

final RandomChooser _defaultChooser = new RandomChooser();
final DummyEnvironment _dummyEnvironment = new DummyEnvironment();

Iterable<SudokuBoard> searchSolution(
  SudokuBoard problem, {
  SolveEnvironment env,
  Chooser chooser,
  int depth = 0,
}) sync* {
  if (env == null) env = _dummyEnvironment;
  if (chooser == null) chooser = _defaultChooser;
  bool solved = problem.eliminateOptions(env);
  problem.eliminateResolved();
  solved = problem.eliminateOptions(env);
  if (!problem.solvable) return;
  if (solved) {
    problem.flatten();
    yield problem.clone();
    return;
  }
  int minimumUnresolved = problem.loupe.cells
      .where((l) => !l.solved)
      .fold(9, (int prev, SudokuLoupe l) => min(prev, l.candidates.length));
  List<int> options = problem.loupe.cells
      .where((l) => !l.solved && l.candidates.length == minimumUnresolved)
      .map((l) => l.index)
      .toList(growable: false);
  final int index = chooser.chooseRandom(options);
  problem.loupe.index = index;
  options = problem.loupe.candidates.toList(growable: false);
  chooser.shuffle(options);
  for (int value in options) {
    Uint32List save = new Uint32List.fromList(problem.backing);
    SudokuLoupe loupe = problem.loupe;
    loupe.index = index;
    loupe.value = value;

    yield* searchSolution(problem,
        env: env, chooser: chooser, depth: depth + 1);

    problem.backing.setAll(0, save);
  }
}

SudokuBoard generateProblem({Chooser chooser}) {
  if (chooser == null) chooser = _defaultChooser;
  List<int> order = new List.generate(81, (i) => i);
  while (true) {
    chooser.shuffle(order);
    SudokuBoard board = new SudokuBoard();
    Set<int> candidatesUsed = new Set();
    int lastFilled = -1;
    for (int i = 0; i < 40; ++i) {
      SudokuBoard checker = board.clone()..eliminateOptions();
      if (!checker.solvable) break;
      int cell = -1;
      for (int j = lastFilled + 1; j < order.length; ++j) {
        final int index = order[j];
        checker.loupe.index = index;
        if (!checker.loupe.solved) {
          lastFilled = j;
          cell = index;
          break;
        }
      }
      List<int> c = checker.loupe[cell].candidates.toList();
      int candidate = chooser.chooseRandom(c);
      candidatesUsed.add(candidate);
      board.loupe[cell].value = candidate;
      int solvedCount = i + 1;
      if (solvedCount >= 17 && candidatesUsed.length >= 8) {
        int solutions = searchSolution(board.clone()).take(2).length;
        if (solutions == 0)
          break;
        else if (solutions == 1) return board;
      }
    }
  }
}
