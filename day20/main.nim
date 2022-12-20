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

proc parseFile(file: string): seq[int64] = lines(file).toSeq.mapIt(int64(it.parseInt))

proc mix(input: seq[int64], steps: int = 0, key: int64 = 1'i64, times: int = 1): seq[int64] =
    var items = newSeq[Item]()
    for index, value in input:
        items.add((index, value * int64(key)))

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
                    var xx = newIndex
                    while xx <= 0:
                        xx += items.len() - 1
                    let before = newIndex
                    newIndex = -(newIndex mod -(items.len() - 1))
                    echo &"{before} -> {newIndex} (len = {items.len()}) -- should be {xx}"

                if newIndex > items.len():
                    newIndex = newIndex mod (items.len() - 1)
                #while newIndex > items.len():
                #    newIndex -= items.len() - 1

                items.delete(actualIndex..actualIndex)
                items.insert(@[item], int(newIndex))

            if steps > 0 and idx + 1 == steps:
                break
    return items.mapIt(it[1])

proc part1(file: string): int =
    let mixed = mix(parseFile(file))

    let indexOfValue0 = findIndex(mixed, proc (n: int64): bool = n == 0'i64)
    proc valueAt(i: int): int64 = mixed[(indexOfValue0 + i) mod mixed.len()]
    return int(valueAt(1000) + valueAt(2000) + valueAt(3000))

proc part2(file: string): int64 =
    let mixed = mix(parseFile(file), 0, 811589153'i64, 10)

    let indexOfValue0 = findIndex(mixed, proc (n: int64): bool = n == 0'i64)
    proc valueAt(i: int): int64 = mixed[(indexOfValue0 + i) mod mixed.len()]
    return valueAt(1000) + valueAt(2000) + valueAt(3000)

suite "day 20":
    test "mix":
        let items = parseFile("example")
        # check(mix(items, 1).mapIt(int(it)) == @[2, 1, -3, 3, -2, 0, 4])
        # check(mix(items, 2).mapIt(int(it)) == @[1, -3, 2, 3, -2, 0, 4])
        check(mix(items, 3).mapIt(int(it)) == @[1, 2, 3, -2, -3, 0, 4])
        # check(mix(items, 4).mapIt(int(it)) == @[1, 2, -2, -3, 0, 3, 4])
        # check(mix(items, 5).mapIt(int(it)) == @[1, 2, -3, 0, 3, 4, -2])
        # check(mix(items, 6).mapIt(int(it)) == @[1, 2, -3, 0, 3, 4, -2])
        # check(mix(items).mapIt(int(it))    == @[1, 2, -3, 4, 0, 3, -2])

        # check(mix(@[1, 0]).mapIt(int(it)) == @[0, 1])
        # check(mix(@[0, 1]).mapIt(int(it)) == @[0, 1])
        # check(mix(@[2, 0, 0]).mapIt(int(it)) == @[0, 0, 2])
        # check(mix(@[0, 0, -2]).mapIt(int(it)) == @[0, 0, -2])
        # check(mix(@[4, 0, 0]).mapIt(int(it)) == @[0, 0, 4])
        # check(mix(@[0, 0, -3]).mapIt(int(it)) == @[0, -3, 0])

    # test "nim":
    #     check(-5 mod 2 == -1)

    # test "part 1":
    #     check(part1("example") == 3'i64)
    #     check(part1("input") == 7713'i64)

    #test "part 2":
    #    check(part2("example") == 1623178306)