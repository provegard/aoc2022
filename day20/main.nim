import sequtils
import strutils
import unittest
import sets
import options
import sugar
import algorithm
import strformat
import math
import ../utils/utils

# (index, value)
type Item = (int, int64)

proc parseFile(file: string): seq[int64] = lines(file).toSeq.mapIt(int64(it.parseInt()))

proc mix(input: seq[int64], steps: int = 0, key: int64 = 1'i64, times: int = 1): seq[int64] =
    var items = newSeq[Item]()
    for index, value in input:
        items.add((index, value * key))

    proc valueAt(x: int): int64 =
        var x2 = x
        if x2 < 0:
            x2 += items.len()
        return items[x2 mod items.len()][1]

    for t in 1..times:
        for idx in 0..<items.len():
            let actualIndex = findIndex(items, proc (item: Item): bool = item[0] == idx)
            assert actualIndex >= 0
            let item = items[actualIndex]
            let itemValue = item[1]
            if itemValue != 0:
                var newIndex = actualIndex + itemValue
                if newIndex <= 0:
                    let nn = items.len() - 1
                    let dd = -(newIndex div nn)
                    newIndex = newIndex + nn * (dd + 1)

                if newIndex > items.len():
                    newIndex = newIndex mod (items.len() - 1)

                items.delete(actualIndex..actualIndex)
                items.insert(@[item], int(newIndex))

            if steps > 0 and idx + 1 == steps:
                break
    return items.mapIt(it[1])

proc part1(file: string): int64 =
    let mixed = mix(parseFile(file))

    let indexOfValue0 = findIndex(mixed, proc (n: int64): bool = n == 0'i64)
    proc valueAt(i: int): int64 = mixed[(indexOfValue0 + i) mod mixed.len()]
    return valueAt(1000) + valueAt(2000) + valueAt(3000)

proc part2(file: string): int64 =
    let mixed = mix(parseFile(file), 0, 811589153'i64, 10)

    let indexOfValue0 = findIndex(mixed, proc (n: int64): bool = n == 0'i64)
    proc valueAt(i: int): int64 = mixed[(indexOfValue0 + i) mod mixed.len()]
    return valueAt(1000) + valueAt(2000) + valueAt(3000)

proc mapToInt(s: seq[int64]): seq[int] = s.mapIt(int(it))
proc mapToInt64(s: seq[int]): seq[int64] = s.mapIt(int64(it))

suite "day 20":
    test "mix":
        let items = parseFile("example")
        check(mix(items, 1).mapToInt() == @[2, 1, -3, 3, -2, 0, 4])
        check(mix(items, 2).mapToInt() == @[1, -3, 2, 3, -2, 0, 4])
        check(mix(items, 3).mapToInt() == @[1, 2, 3, -2, -3, 0, 4])
        check(mix(items, 4).mapToInt() == @[1, 2, -2, -3, 0, 3, 4])
        check(mix(items, 5).mapToInt() == @[1, 2, -3, 0, 3, 4, -2])
        check(mix(items, 6).mapToInt() == @[1, 2, -3, 0, 3, 4, -2])
        check(mix(items).mapToInt()    == @[1, 2, -3, 4, 0, 3, -2])

        check(mix(@[1, 0].mapToInt64()).mapToInt() == @[0, 1])
        check(mix(@[0, 1].mapToInt64()).mapToInt() == @[0, 1])
        check(mix(@[2, 0, 0].mapToInt64()).mapToInt() == @[0, 0, 2])
        check(mix(@[0, 0, -2].mapToInt64()).mapToInt() == @[0, 0, -2])
        check(mix(@[0, 0, -3].mapToInt64()).mapToInt()== @[0, -3, 0])

    test "part 1":
        check(part1("example") == 3'i64)
        check(part1("input") == 7713'i64)

    test "part 2":
       check(part2("example") == 1623178306'i64)
       check(part2("input") == 1664569352803'i64)
