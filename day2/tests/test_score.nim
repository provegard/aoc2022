import std/unittest
import ../src/score

suite "score":

    test "first":
        check(calcRoundScore("A X") == 4)