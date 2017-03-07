import "package:sudoku_core/sudoku_core.dart";
import "package:test/test.dart";

const List<List<String>> solvedCases = const [
  const [
    "..3.2.6..9..3.5..1..18.64....81.29..7.......8..67.82....26.95..8..2.3..9..5.1.3..",
    "483921657967345821251876493548132976729564138136798245372689514814253769695417382",
  ],
  const [
    "4.....8.5.3..........7......2.....6.....8.4......1.......6.3.7.5..2.....1.4......",
    "417369825632158947958724316825437169791586432346912758289643571573291684164875293",
  ],
];

void main(List<String> args) {
  for (int i = 0; i < solvedCases.length; ++i) {
    List<String> testCase = solvedCases[i];
    test("Presolved testcase #${i+1}", () {
      List<String> solutions =
          searchSolution(new SudokuBoard.fromString(testCase[0]))
              .map((board) => board.toString())
              .toList(growable: false);
      List<String> expected = testCase.skip(1).toList(growable: false);
      expected.sort();
      solutions.sort();
      for (String solution in solutions) {
        Map<int, int> numberCount = {};
        for (int code in solution.runes) {
          expect(code, inInclusiveRange(0x31, 0x39));
          numberCount[code] ??= 0;
          ++numberCount[code];
        }
        expect(new List.filled(9, 9), numberCount.values.toList());
      }
      expect(solutions, equals(expected));
    });
  }
}
