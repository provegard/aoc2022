import sequtils
import strutils
import unittest
import options
import algorithm
import strformat
import std/nre except toSeq
import tables
import ../utils/utils
import times

type
    Valve = ref object
        id: string
        flowRate: int
        next: seq[string]
    State = ref object
        playerPaths: seq[seq[string]]
        openValves: Table[string, int] # key = valve ID, value = time it will be open
        timeLeft: int

proc newValve(id: string, flowRate: int, next: seq[string]): Valve =
    Valve(id: id, flowRate: flowRate, next: next)

let lineMatch = re"^Valve ([A-Z]+) has flow rate=([0-9]+); tunnels? leads? to valves? (.+)$"

proc parseLine(line: string): Valve =
    let m = line.match(lineMatch)
    assert m.isSome
    let id = m.get.captures[0]
    let fr = m.get.captures[1].parseInt()
    let next = m.get.captures[2].replace(",", "").split(" ")
    return newValve(id, fr, next)

proc createLookup(valves: seq[Valve]): Table[string, Valve] =
    var tab = initTable[string, Valve]()
    for v in valves:
        tab[v.id] = v
    return tab

proc neighbors(tab: Table[string, Valve], id: string): seq[string] = tab[id].next

proc findPath(tab: Table[string, Valve], start: string, target: string): seq[string] =
    var dist = initTable[string, int]()
    var prev = initTable[string, string]()
    for id in tab.keys:
        dist[id] = 10000

    proc minF(c: string, d: Table[string, int]): int = d[c]

    dist[start] = 0
    var q = tab.keys.toSeq
    while q.len() > 0:
        let uidx = minByIdx(q, minF, dist)
        let u = q[uidx]

        if u == target:
            var s = newSeq[string]()
            var x = target
            if prev.contains(x) or x == start:
                while true:
                    s.add(x)
                    if not prev.contains(x):
                        break
                    x = prev[x]
            reverse(s)
            return s

        q.delete(uidx)
        for v in neighbors(tab, u):
            let alt = dist[u] + 1
            if alt < dist[v]:
                dist[v] = alt
                prev[v] = u
    return newSeq[string]()

proc sumPressures(tab: Table[string, Valve], state: State): int =
    var p = 0
    for (id, timeOpen) in state.openValves.pairs:
        let valve = tab[id]
        p += valve.flowRate * timeOpen
    return p

proc openableValveIds(valves: Table[string, Valve], state: State): seq[string] =
    return valves.keys.toSeq.filter(proc (id: string): bool = 
        let valve = valves[id]
        return valve.flowRate > 0 and not state.openValves.contains(id)
    )

proc go(valves: Table[string, Valve], state: State): int =
    if state.timeLeft <= 0:
        return sumPressures(valves, state)

    let playerPath = state.playerPaths[0]
    let isAtEnd = playerPath.len() == 1
    let valveId = playerPath[0]
    let openable = openableValveIds(valves, state)
    let canOpen = openable.contains(valveId)

    if isAtEnd and canOpen:
        # spend one minute to open
        var newOpenValves = state.openValves
        newOpenValves[valveId] = state.timeLeft - 1
        let newState = State(openValves: newOpenValves, playerPaths: state.playerPaths, timeLeft: state.timeLeft - 1)
        return go(valves, newState)
    elif isAtEnd:
        if openable.len() == 0:
            return sumPressures(valves, state)

        # plot a new path
        var res = newSeq[int]()

        for targetId in openable:
            let path = findPath(valves, valveId, targetId)
            if path.len() == 0:
                continue
            let movePath = path[1..^1] # head is start, so skip it
            let newPaths = @[movePath]
            let newState = State(openValves: state.openValves, playerPaths: newPaths, timeLeft: state.timeLeft - 1)
            let ret = go(valves, newState)
            res.add(ret)

        assert res.len() > 0, "No results??"
        return res.max()
    else:
        # continue on current path
        let newPaths = @[playerPath[1..^1]]
        let newState = State(openValves: state.openValves, playerPaths: newPaths, timeLeft: state.timeLeft - 1)
        return go(valves, newState)


proc newState(): State = State(playerPaths: @[@["AA"]], openValves: initTable[string, int](), timeLeft: 30)

proc part1(file: string): int =
    let lookup = createLookup(lines(file).toSeq.map(parseLine))
    let before = cpuTime()
    let initialState = newState()
    let ret = go(lookup, initialState)
    let elapsed = int(1000 * (cpuTime() - before))
    echo &"file {file} took {elapsed} ms"
    return ret

suite "day 16":
    test "parseLine":
        let v = parseLine("Valve AA has flow rate=2; tunnels lead to valves DD, II, BB")
        check(v.id == "AA")
        check(v.flowRate == 2)
        #check(v.open == false)
        check(v.next == @["DD", "II", "BB"])
        #check(v.totalPressure == 0)

    test "part1":
        check(part1("example") == 1651)
        #check(part1("input") == 1792)