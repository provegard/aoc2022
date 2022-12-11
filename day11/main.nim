import sequtils
import strutils
import unittest
import options
import algorithm
import Tables
import ../utils/utils
import math

type
    Operation = ref object
        operator: char
        value: int

type
    Monkey = ref object
        id: int
        items: seq[int]
        operation: Operation
        divisor: int
        trueTo: int
        falseTo: int

proc parse(ll: seq[string]): Table[int, Monkey] =
    var tab = initTable[int, Monkey]()
    var monkey: Option[Monkey] = none[Monkey]()
    for line in ll:
        let parts = line.strip().split({' ', ',', ':'})
        if parts[0] == "Monkey":
            # Save current
            monkey.doOpt(proc (m: Monkey) = tab[m.id] = m)
            monkey = some(Monkey(id: parts[1].parseInt))
        elif parts[0] == "Starting":
            monkey.get.items = parts.filterIt(it != "").skip(2).mapIt(parseInt(it))
        elif parts[0] == "Operation":
            let opp = parts.skip(5)
            let op = if opp[1] == "old":
                Operation(operator: '^', value: 2)
            else:
                Operation(operator: opp[0][0], value: opp[1].parseInt)
            monkey.get.operation = op
        elif parts[0] == "Test":
            monkey.get.divisor = parts[^1].parseInt
        elif parts[0] == "If" and parts[1] == "true":
            monkey.get.trueTo = parts[^1].parseInt
        elif parts[0] == "If" and parts[1] == "false":
            monkey.get.falseTo = parts[^1].parseInt

    monkey.doOpt(proc (m: Monkey) = tab[m.id] = m)
    return tab

# base calculation for new worry value
proc calcNewWorryBase(m: Monkey, old: int): int =
    return case m.operation.operator
        of '*': old * m.operation.value
        of '+': old + m.operation.value
        of '^': old ^ m.operation.value
        else: old

# part 1, divide by 3
proc calcNewWorry1(m: Monkey, old: int): int = calcNewWorryBase(m, old) div 3

# part 2, factory function for worry calculator that doesn't divide, but that keeps worry values reasonable
proc createCalcNewWorry2(monkeys: Table[int, Monkey]): proc (m: Monkey, old: int): int =
    let md = monkeys.values().toSeq().mapIt(it.divisor).foldl(a * b, 1)
    return proc (m: Monkey, old: int): int = calcNewWorryBase(m, old) mod md

proc newCounters(monkeys: Table[int, Monkey]): Table[int, int] =
    return monkeys.values.toSeq.mapIt((it.id, 0)).toTable

proc monkeyTurn(id: int, monkeys: Table[int, Monkey], counters: var Table[int, int], calc: proc (m: Monkey, old: int): int) =
    var monkey = monkeys[id]
    for item in monkey.items:
        let newWorry = calc(monkey, item)
        let isDivisible = newWorry mod monkey.divisor == 0
        let targetMonkey = if isDivisible: monkey.trueTo else: monkey.falseTo
        monkeys[targetMonkey].items.add(newWorry)
    counters[monkey.id] += monkey.items.len()
    monkey.items.setLen(0)

proc oneTurn(monkeys: Table[int, Monkey], counters: var Table[int, int], calc: proc (m: Monkey, old: int): int = calcNewWorry1) =
    for i in 0..<monkeys.len():
        monkeyTurn(i, monkeys, counters, calc)

proc monkeyBusiness(monkeys: Table[int, Monkey], rounds: int, calc: proc (m: Monkey, old: int): int): int =
    var counters = newCounters(monkeys)
    for i in 1..rounds:
        oneTurn(monkeys, counters, calc)

    var v = counters.values.toSeq
    v.sort(SortOrder.Descending)
    return v[0] * v[1]

proc part1(file: string): int =
    let ll = lines(file).toSeq
    let monkeys = parse(ll)
    return monkeyBusiness(monkeys, 20, calcNewWorry1)

proc part2(file: string): int =
    let ll = lines(file).toSeq
    let monkeys = parse(ll)
    return monkeyBusiness(monkeys, 10000, createCalcNewWorry2(monkeys))

suite "day 11":
    test "parse 1":
        let ll = @[
            "Monkey 0:",
            "  Starting items: 79, 98",
            "  Operation: new = old * 19",
            "  Test: divisor by 23",
            "    If true: throw to monkey 2",
            "    If false: throw to monkey 3"
        ]
        let tab = parse(ll)
        check(tab.len() == 1)
        check(tab[0].id == 0)
        check(tab[0].items == @[79, 98])
        check(tab[0].operation.operator == '*')
        check(tab[0].operation.value == 19)
        check(tab[0].divisor == 23)
        check(tab[0].trueTo == 2)
        check(tab[0].falseTo == 3)

    test "parse 2":
        let ll = @[
            "Monkey 0:",
            "  Starting items: 79, 98",
            "  Operation: new = old * old",
            "  Test: divisor by 23",
            "    If true: throw to monkey 2",
            "    If false: throw to monkey 3"
        ]
        let tab = parse(ll)
        check(tab[0].operation.operator == '^')
        check(tab[0].operation.value == 2)

    test "oneTurn":
        let ll = lines("example").toSeq
        let tab = parse(ll)

        var counters = newCounters(tab)
        oneTurn(tab, counters)

        check(tab[0].items == @[20, 23, 27, 26])
        check(tab[1].items == @[2080, 25, 167, 207, 401, 1046])
        check(tab[2].items == newSeq[int]())
        check(tab[3].items == newSeq[int]())
        check(counters[0] == 2)

    test "oneTurn * 20":
        let ll = lines("example").toSeq
        let tab = parse(ll)

        var counters = newCounters(tab)
        for i in 1..20:
            oneTurn(tab, counters)

        check(tab[0].items == @[10, 12, 14, 26, 34])
        check(tab[1].items == @[245, 93, 53, 199, 115])
        check(tab[2].items == newSeq[int]())
        check(tab[3].items == newSeq[int]())

    test "inspected after 20, no relief":
        let ll = lines("example").toSeq
        let tab = parse(ll)

        var counters = newCounters(tab)
        for i in 1..20:
            oneTurn(tab, counters, createCalcNewWorry2(tab))

        check(counters[0] == 99)
        check(counters[1] == 97)
        check(counters[2] == 8)
        check(counters[3] == 103)

    test "inspected after 1000, no relief":
        let ll = lines("example").toSeq
        let tab = parse(ll)

        var counters = newCounters(tab)
        for i in 1..1000:
            oneTurn(tab, counters, createCalcNewWorry2(tab))

        check(counters[0] == 5204)
        check(counters[1] == 4792)
        check(counters[2] == 199)
        check(counters[3] == 5192)

    test "part1":
        check(part1("example") == 10605)
        check(part1("input") == 69918)

    test "part2":
        check(part2("example") == 2713310158)
        check(part2("input") == 19573408701)
