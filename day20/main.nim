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
type Item = (int, int)

proc parseFile(file: string): seq[int] = lines(file).toSeq.map(parseInt)

proc mix(input: seq[int], steps: int = 0): seq[int] =
    var items = newSeq[Item]()
    for index, value in input:
        items.add((index, value))

    proc valueAt(x: int): int =
        var x2 = x
        if x2 < 0:
            x2 += items.len()
        return items[x2 mod items.len()][1]

    for idx in 0..<items.len():
        let actualIndex = findIndex(items, proc (item: Item): bool = item[0] == idx)
        assert actualIndex >= 0
        let item = items[actualIndex]
        let itemValue = item[1]
        if itemValue != 0:
            var newIndex = actualIndex + itemValue
            while newIndex <= 0:
                newIndex += items.len() - 1
            while newIndex > items.len():
                newIndex -= items.len() - 1

            items.delete(actualIndex..actualIndex)
            items.insert(@[item], newIndex)

            let valueBefore = valueAt(newIndex - 1)
            let valueAfter = valueAt(newIndex + 1)

        if steps > 0 and idx + 1 == steps:
            break
    return items.mapIt(it[1])

proc part1(file: string): int =
    let mixed = mix(parseFile(file))

    let indexOfValue0 = findIndex(mixed, proc (n: int): bool = n == 0)
    proc valueAt(i: int): int = mixed[(indexOfValue0 + i) mod mixed.len()]
    return valueAt(1000) + valueAt(2000) + valueAt(3000)


suite "day 20":
    test "mix":
        let items = parseFile("example")
        check(mix(items, 1) == @[2, 1, -3, 3, -2, 0, 4])
        check(mix(items, 2) == @[1, -3, 2, 3, -2, 0, 4])
        check(mix(items, 3) == @[1, 2, 3, -2, -3, 0, 4])
        check(mix(items, 4) == @[1, 2, -2, -3, 0, 3, 4])
        check(mix(items, 5) == @[1, 2, -3, 0, 3, 4, -2])
        check(mix(items, 6) == @[1, 2, -3, 0, 3, 4, -2])
        check(mix(items)    == @[1, 2, -3, 4, 0, 3, -2])

        check(mix(@[1, 0]) == @[0, 1])
        check(mix(@[0, 1]) == @[0, 1])
        check(mix(@[2, 0, 0]) == @[0, 0, 2])
        check(mix(@[0, 0, -2]) == @[0, 0, -2])
        check(mix(@[4, 0, 0]) == @[0, 0, 4])
        check(mix(@[0, 0, -3]) == @[0, -3, 0])

    test "part 1":
        check(part1("example") == 3)
        check(part1("input") == 7713)