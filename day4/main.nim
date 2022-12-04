import std/sequtils
import std/strutils
import std/unittest
import std/sets
import sugar

type IntTuple = (int, int)

proc tuples(s: string): (IntTuple, IntTuple) =
    let parts = s.split({',', '-'}).mapIt(parseInt(it))
    return ((parts[0], parts[1]), (parts[2], parts[3]))

proc fullyContains(a: IntTuple, b: IntTuple): bool =
    proc c(a: IntTuple, b: IntTuple): bool = a[0] <= b[0] and a[1] >= b[1]
    return c(a, b) or c(b, a)

proc overlap(a: IntTuple, b: IntTuple): bool =
    proc c(a: IntTuple, b: IntTuple): bool = a[0] >= b[0] and a[0] <= b[1]
    return c(a, b) or c(b, a)

proc part(file: string, alg: (IntTuple, IntTuple) -> bool): int =
    let ll = lines(file).toSeq().map(tuples)
    return ll.filterIt(alg(it[0], it[1])).len()

proc part1(file: string): int = part(file, fullyContains)

proc part2(file: string): int = part(file, overlap)

suite "day 4":
    test "tuples":
        check(tuples("2-4,6-8") == ((2, 4), (6, 8)))

    test "fullyContains":
        check(fullyContains((1, 2), (3, 4)) == false)
        check(fullyContains((1, 2), (2, 3)) == false)
        check(fullyContains((1, 2), (1, 2)) == true)
        check(fullyContains((1, 4), (2, 3)) == true)
        check(fullyContains((2, 3), (1, 4)) == true)

    test "overlap":
        check(overlap((1, 2), (3, 4)) == false)
        check(overlap((1, 2), (2, 3)) == true)
        check(overlap((2, 3), (1, 2)) == true)
        check(overlap((1, 2), (1, 2)) == true)
        check(overlap((1, 4), (2, 3)) == true)
        check(overlap((2, 3), (1, 4)) == true)

    test "part1":
        check(part1("example") == 2)
        check(part1("input") == 498)

    test "part2":
        check(part2("example") == 4)
        check(part2("input") == 859)