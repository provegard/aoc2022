import sequtils
import strutils
import unittest
import options
import strformat
import math
import nre except toSeq
import tables
import deques
import ../utils/utils

type
    ExpressionKind = enum ekBinary, ekTerm, ekValue
    Expression = ref object
        case kind: ExpressionKind:
        of ekTerm:
            term: string
        of ekValue:
            value: int64
        of ekBinary:
            left: Expression
            right: Expression
            operator: string
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

proc `==`(a, b: Expression): bool =
    if a.kind != b.kind:
        return false
    if a.kind == ekValue:
        return a.value == b.value
    if a.kind == ekTerm:
        return a.term == b.term
    return a.operator == b.operator and a.left == b.left and a.right == b.right

proc `$`(e: Expression): string =
    return case e.kind
        of ekValue: $e.value
        of ekTerm: e.term
        of ekBinary: &"({e.left} {e.operator} {e.right})"

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
    of "=": int64(left == right)
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

proc simplify(exp: Expression): Expression

proc valueExp(v: int64): Expression = Expression(kind: ekValue, value: v)
proc termExp(t: string): Expression = Expression(kind: ekTerm, term: t)
proc binExp(a, b: Expression, op: string): Expression = Expression(kind: ekBinary, left: a, right: b, operator: op)

proc `*`(a, b: Expression): Expression =
    let sa = simplify(a)
    let sb = simplify(b)
    if sa.kind == ekValue and sb.kind == ekValue:
        return valueExp(sa.value * sb.value)
    elif sa.kind == ekValue:
        return sb * sa
    elif sb.kind == ekValue and sb.value == 1'i64:
        return sa
    elif sa.kind == ekBinary and sb.kind == ekValue:
        if sa.operator == "*" and sa.right.kind == ekValue:
            # left * (right * sb)
            let newRight = sa.right.value * sb.value
            return binExp(sa.left, valueExp(newRight), "*")
        if sa.operator == "/" and sa.right.kind == ekValue:
            if sa.right.value > sb.value and sa.right.value mod sb.value == 0:
                # left / (right / sb)
                let newRight = sa.right.value div sb.value
                return binExp(sa.left, valueExp(newRight), "/")
            if sa.right.value <= sb.value and sb.value mod sa.right.value == 0:
                # left * (sb / right)
                let newRight = sb.value div sa.right.value
                return simplify(binExp(sa.left, valueExp(newRight), "*"))
        if sa.operator == "+" and sa.right.kind == ekValue:
            # (left * sb) + (right * sb)
            let newLeft = sa.left * sb
            let newRight = sa.right * sb
            return binExp(newLeft, newRight, "+")

    return binExp(a, b, "*")

proc `/`(a, b: Expression): Expression =
    let sa = simplify(a)
    let sb = simplify(b)
    if sa == sb:
        return valueExp(1)
    elif sa.kind == ekValue and sb.kind == ekValue:
        if sa.value mod sb.value == 0:
            return valueExp(sa.value div sb.value)
    elif sb.kind == ekValue and sb.value == 1'i64:
        return sa
    elif sa.kind == ekBinary and sb.kind == ekValue:
        if sa.operator == "*" and sa.right.kind == ekValue:
            if sa.right.value mod sb.value == 0:
                # left * (right / sb)
                let newRight = sa.right.value div sb.value
                return simplify(binExp(sa.left, valueExp(newRight), "*"))
        elif sa.operator == "+" and sa.right.kind == ekValue:
            if sa.right.value mod sb.value == 0:
                # (left / sb) + (right / sb)
                let newLeft = sa.left / sb
                let newRight = valueExp(sa.right.value div sb.value)
                return simplify(binExp(newLeft, newRight, "+"))
        elif sa.operator == "/" and sa.right.kind == ekValue:
            # left / (right * sb)
            let newRight = valueExp(sa.right.value * sb.value)
            return simplify(binExp(sa.left, newRight, "/"))
    return binExp(a, b, "/")

proc `+`(a, b: Expression): Expression =
    let sa = simplify(a)
    let sb = simplify(b)
    if sa.kind == ekValue and sb.kind == ekValue:
        return valueExp(sa.value + sb.value)
    elif sa.kind == ekValue:
        return sb + sa
    elif sb.kind == ekValue and sb.value == 0'i64:
        return sa
    elif sa.kind == ekBinary and sb.kind == ekValue:
        if sa.operator == "+" and sa.right.kind == ekValue:
            # left + right + thisval
            let newRight = sa.right.value + sb.value
            return simplify(binExp(sa.left, valueExp(newRight), "+"))
    return binExp(a, b, "+")

proc `-`(a, b: Expression): Expression =
    let sa = simplify(a)
    let sb = simplify(b)
    if sa.kind == ekValue and sb.kind == ekValue:
        return valueExp(sa.value - sb.value)
    elif sb.kind == ekValue:
        return sa + valueExp(-sb.value)
    return binExp(a, b, "-")

proc eq(a, b: Expression): Expression =
    let sa = simplify(a)
    let sb = simplify(b)
    if sa.kind == ekBinary and sb.kind == ekValue:
        if sa.operator == "*" and sa.right.kind == ekValue and sb.value mod sa.right.value == 0'i64:
            let newLeft = sa / sa.right
            let newRight = valueExp(sb.value div sa.right.value)
            return simplify(binExp(newLeft, newRight, "="))
        elif sa.operator == "/" and sa.right.kind == ekValue:
            let newLeft = sa * sa.right
            let newRight = valueExp(sb.value * sa.right.value)
            return simplify(binExp(newLeft, newRight, "="))
        elif sa.operator == "+" and sa.right.kind == ekValue:
            let newLeft = sa - sa.right
            let newRight = valueExp(sb.value - sa.right.value)
            return simplify(binExp(newLeft, newRight, "="))
        elif sa.operator == "-" and sa.left.kind == ekValue:
            # tricky
            # add sa.right on both sides, then swap
            let newLeft = sa.left
            let newRight = sb + sa.right
            # swap
            return simplify(binExp(newRight, newLeft, "="))
    return binExp(a, b, "=")

proc simplify(exp: Expression): Expression =
    case exp.kind:
        of ekBinary:
            case exp.operator:
                of "*": return exp.left * exp.right
                of "/": return exp.left / exp.right
                of "+": return exp.left + exp.right
                of "-": return exp.left - exp.right
                of "=": return eq(exp.left, exp.right)
                else: return exp
        else:
            return exp

proc buildExpression2(nodes: seq[Node]): Expression =
    var mem = initTable[string, Expression]()
    var queue = nodes.toDeque
    while queue.len() > 0:
        let n = queue.popFirst
        
        if n.kind == nkValue:
            if n.id == "humn":
                mem[n.id] = termExp(n.id)
            else:
                mem[n.id] = valueExp(n.value)
        
        elif mem.contains(n.op.left) and mem.contains(n.op.right):
            let left = mem[n.op.left]
            let right = mem[n.op.right]
            let exp = simplify(binExp(left, right, n.op.operator))
            mem[n.id] = exp
        
        else:
            queue.addLast(n)
    
    return mem["root"]

proc part1(file: string): int64 = calculate(parseFile(file))

proc part2(file: string): int64 =
    var nodes = parseFile(file)
    let rootIndex = findIndex(nodes, proc (n: Node): bool = n.id == "root")
    nodes[rootIndex].op.operator = "="
    let exp = buildExpression2(nodes)
    echo exp
    if exp.kind == ekBinary and exp.left.kind == ekTerm and exp.left.term == "humn":
        if exp.right.kind == ekValue:
            return exp.right.value
    return 0'i64

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

    test "nim":
        check(int64(false) == 0'i64)
        check(int64(true) == 1'i64)

    test "simplify":
        check(simplify(valueExp(5)) == valueExp(5))
        check(simplify(binExp(valueExp(5), valueExp(6), "*")) == valueExp(30))
        check(simplify(binExp(valueExp(5), valueExp(6), "+")) == valueExp(11))
        check(
            simplify(
                binExp(
                    binExp(termExp("X"), valueExp(2), "*"),
                    valueExp(3),
                    "*"
                )
            ) == binExp(termExp("X"), valueExp(6), "*")
        )

        check(
            simplify(
                binExp(
                    binExp(
                        binExp(termExp("X"), valueExp(2), "*"),
                        valueExp(3),
                        "*"
                    ),
                    valueExp(2),
                    "*"
                )
            ) == binExp(termExp("X"), valueExp(12), "*")
        )

        check(
            simplify(
                binExp(
                    binExp(termExp("X"), valueExp(6), "*"),
                    valueExp(3),
                    "/"
                )
            ) == binExp(termExp("X"), valueExp(2), "*")
        )

        check(
            simplify(
                binExp(
                    binExp(termExp("X"), valueExp(6), "/"),
                    valueExp(3),
                    "*"
                )
            ) == binExp(termExp("X"), valueExp(2), "/")
        )

        check(
            simplify(
                binExp(
                    binExp(termExp("X"), valueExp(6), "/"),
                    valueExp(12),
                    "*"
                )
            ) == binExp(termExp("X"), valueExp(2), "*")
        )

        check(
            simplify(
                binExp(
                    binExp(termExp("X"), valueExp(6), "/"),
                    valueExp(6),
                    "*"
                )
            ) == termExp("X")
        )

        check(
            simplify(
                binExp(
                    binExp(termExp("X"), valueExp(6), "*"),
                    valueExp(6),
                    "/"
                )
            ) == termExp("X")
        )

        check(
            simplify(
                binExp(
                    binExp(termExp("X"), valueExp(6), "+"),
                    valueExp(5),
                    "+"
                )
            ) == binExp(termExp("X"), valueExp(11), "+")
        )

        check(
            simplify(
                binExp(
                    binExp(valueExp(6), termExp("X"), "+"),
                    valueExp(5),
                    "+"
                )
            ) == binExp(termExp("X"), valueExp(11), "+")
        )

        check(
            simplify(
                binExp(
                    termExp("X"),
                    valueExp(0),
                    "+"
                )
            ) == termExp("X")
        )

        check(
            simplify(
                binExp(
                    termExp("X"),
                    valueExp(1),
                    "*"
                )
            ) == termExp("X")
        )

        check(
            simplify(
                binExp(
                    termExp("X"),
                    valueExp(1),
                    "/"
                )
            ) == termExp("X")
        )

        check(
            simplify(
                binExp(
                    termExp("X"),
                    termExp("X"),
                    "/"
                )
            ) == valueExp(1)
        )

        check(simplify(binExp(valueExp(6), valueExp(5), "-")) == valueExp(1))
        check(simplify(binExp(termExp("X"), valueExp(0), "-")) == termExp("X"))

        check(
            simplify(
                binExp(
                    binExp(valueExp(6), termExp("X"), "+"),
                    valueExp(5),
                    "-"
                )
            ) == binExp(termExp("X"), valueExp(1), "+")
        )

        check(
            simplify(
                binExp(
                    binExp(valueExp(2), termExp("X"), "+"),
                    valueExp(3),
                    "*"
                )
            ) == binExp(
                    binExp(termExp("X"), valueExp(3), "*"),
                    valueExp(6),
                    "+"
                )
        )

        check(
            simplify(
                binExp(
                    binExp(termExp("X"), valueExp(10), "+"),
                    valueExp(2),
                    "/"
                )
            ) == binExp(
                    binExp(termExp("X"), valueExp(2), "/"),
                    valueExp(5),
                    "+"
                )
        )

        check(
            simplify(
                binExp(
                    binExp(termExp("X"), valueExp(2), "/"),
                    valueExp(3),
                    "/"
                )
            ) == binExp(termExp("X"), valueExp(6), "/")
        )

        check(
            simplify(
                binExp(
                    binExp(termExp("X"), valueExp(2), "*"),
                    valueExp(100),
                    "="
                )
            ) == binExp(
                    termExp("X"),
                    valueExp(50),
                    "="
                )
        )

        check(
            simplify(
                binExp(
                    binExp(termExp("X"), valueExp(2), "/"),
                    valueExp(100),
                    "="
                )
            ) == binExp(
                    termExp("X"),
                    valueExp(200),
                    "="
                )
        )

        check(
            simplify(
                binExp(
                    binExp(termExp("X"), valueExp(2), "-"),
                    valueExp(100),
                    "="
                )
            ) == binExp(
                    termExp("X"),
                    valueExp(102),
                    "="
                )
        )

        check(
            simplify(
                binExp(
                    binExp(valueExp(2), termExp("X"), "-"),
                    valueExp(100),
                    "="
                )
            ) == binExp(
                    termExp("X"),
                    valueExp(-98),
                    "="
                )
        )

    test "part 2":
        check(part2("example") == 301'i64)
        check(part2("input") == 3296135418820'i64)