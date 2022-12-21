import sequtils
import strutils
import unittest
import sets
import options
import sugar
import algorithm
import strformat
import math
import nre except toSeq
import tables
import deques

type
    Operation = object
        operator: string
        left: string
        right: string
    NodeKind = enum nkOperation, nkValue
    Node = object
        id: string
        case kind: NodeKind:
        of nkOperation:
            op: Operation
        of nkValue:
            value: int64

proc `==`(a, b: Node): bool =
    if a.kind != b.kind:
        return false
    if a.kind == nkValue:
        return a.value == b.value
    return a.op == b.op

let lineMatch = re"^(?<id>[a-z]{4}): (((?<left>[a-z]{4}) (?<oper>[+*/-]) (?<right>[a-z]{4}))|(?<value>[0-9-]+))$"
proc parseLine(line: string): Node =
    let m = line.match(lineMatch)
    assert m.isSome

    let id = m.get.captures["id"]
    if m.get.captures.contains("value"):
        let value = int64(m.get.captures["value"].parseInt)
        return Node(kind: nkValue, id: id, value: value)

    let left = m.get.captures["left"]
    let oper = m.get.captures["oper"]
    let right = m.get.captures["right"]
    let op = Operation(operator: oper, left: left, right: right)
    return Node(kind: nkOperation, id: id, op: op)

proc parseFile(file: string): seq[Node] = lines(file).toSeq.map(parseLine)

proc calc(operator: string, left: int64, right: int64): int64 =
    return case operator
    of "+": left + right
    of "-": left - right
    of "/": left div right
    of "*": left * right
    else: left

proc calculate(nodes: seq[Node]): int64 =
    var mem = initTable[string, int64]()
    var queue = nodes.toDeque
    while queue.len() > 0:
        let n = queue.popFirst
        if n.kind == nkValue:
            mem[n.id] = n.value
        elif mem.contains(n.op.left) and mem.contains(n.op.right):
            mem[n.id] = calc(n.op.operator, mem[n.op.left], mem[n.op.right])
        else:
            queue.addLast(n)
    return mem["root"]

proc part1(file: string): int64 = calculate(parseFile(file))

suite "day 21":
    test "parseLine":
        check(parseLine("dbpl: 5") == Node(kind: nkValue, id: "dbpl", value: 5'i64))
        check(parseLine("dbpl: -5") == Node(kind: nkValue, id: "dbpl", value: -5'i64))
        check(parseLine("root: pppw + sjmn") == Node(
            kind: nkOperation,
            id: "root",
            op: Operation(operator: "+", left: "pppw", right: "sjmn")))

    test "part 1":
        check(part1("example") == 152'i64)
        check(part1("input") == 78342931359552'i64)