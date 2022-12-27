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
import hashes
#import nimprof

type
    Valve = ref object
        id: string
        flowRate: int
        next: seq[string]
    State = ref object
        playerPaths: seq[seq[string]]
        openValves: Table[string, int] # key = valve ID, value = time it will be open
        timeLeft: int
        openableValveIds: seq[string]

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

iterator items(s: State): Hash =
    for idx, path in s.playerPaths:
        for p in path:
            yield hash((idx, p))
    # var keys = s.openValves.keys.toSeq
    # keys.sort(SortOrder.Ascending)
    for id in s.openValves.keys:
        yield hash(id)
    yield hash(s.timeLeft)

proc hash(s: State): Hash =
  var h: Hash = 0
  for xAtom in s:
    h = h !& xAtom
  result = !$h

proc creatCacheKey(s: State): string = $hash(s)

type Cache = Table[string, int]

type AllPaths = Table[(string, string), seq[string]]

proc findAllPaths(valves: Table[string, Valve]): AllPaths =
    var allPaths = initTable[(string, string), seq[string]]()
    for a in valves.keys:
        for b in valves.keys:
            if a == b:
                continue
            var path = findPath(valves, a, b)
            if path.len() > 0:
                # skip start
                path = path[1..^1]
            allPaths[(a, b)] = path
    return allPaths

type
    MoveKind = enum mkOpen, mkMove, mkNothing
    MoveOption = ref object
        playerId: int
        case kind: MoveKind:
        of mkOpen:
            valveId: string
        of mkMove:
            path: seq[string]
        of mkNothing:
            discard

proc openValve(state: State, valveId: string): State =
    var newOpenValves = state.openValves
    newOpenValves[valveId] = state.timeLeft - 1
    let newOpenableIds = state.openableValveIds.filterIt(it != valveId)
    result = State(openValves: newOpenValves, playerPaths: state.playerPaths, timeLeft: state.timeLeft, openableValveIds: newOpenableIds)

proc movePlayer(state: State, playerId: int, path: seq[string]): State =
    var newPaths = state.playerPaths
    newPaths[playerId] = path
    result = State(openValves: state.openValves, playerPaths: newPaths, timeLeft: state.timeLeft, openableValveIds: state.openableValveIds)

proc applyOne(state: State, opt: MoveOption): State =
    result = case opt.kind
        of mkOpen:    state.openValve(opt.valveId)
        of mkMove:    state.movePlayer(opt.playerId, opt.path)
        of mkNothing: state

proc apply(state: State, opt: MoveOption, subTime: int = 1): State =
    var s: State
    if opt.kind == mkMove:
        # move directly to target
        let target = opt.path[^1]
        s = state.movePlayer(opt.playerId, @[target])
        s.timeLeft -= opt.path.len()
    else:
        s = state.applyOne(opt)
        s.timeLeft -= 1
    result = s

proc apply(state: State, opt1, opt2: MoveOption): State =
    var s: State
    if opt1.kind == mkMove and opt2.kind == mkMove:
        let prefixLen = min(opt1.path.len(), opt2.path.len()) - 1
        let p1 = opt1.path[prefixLen..^1]
        let p2 = opt2.path[prefixLen..^1]
        s = state.movePlayer(0, p1).movePlayer(1, p2)
        s.timeLeft -= prefixLen + 1
    else:
        s = state.applyOne(opt1).applyOne(opt2)
        s.timeLeft -= 1
    result = s

proc go(valves: Table[string, Valve], state: State, allPaths: AllPaths, cache: var Cache): int =
    assert state.timeLeft >= 0, "negative time left"

    let cacheKey = creatCacheKey(state)
    let sumPressuresNow = sumPressures(valves, state)

    if cache.contains(cacheKey):
        # cache contains delta
        return sumPressuresNow + cache[cacheKey]

    let openable = state.openableValveIds
    var ret = 0
    if state.timeLeft == 0 or openable.len() == 0:
        ret = sumPressuresNow
    else:
        var moveOptionsPerPlayer = newSeq[seq[MoveOption]]()
        for playerId, pp in state.playerPaths:
            let isAtEnd = pp.len() == 1
            let valveId = pp[0]
            let canOpen = openable.contains(valveId)
        
            var moveOptions = newSeq[MoveOption]()
            if isAtEnd and canOpen:
                moveOptions.add(MoveOption(playerId: playerId, kind: mkOpen, valveId: valveId))
            elif isAtEnd:
                for targetId in openable:
                    let movePath = allPaths[(valveId, targetId)]
                    let moveLen = movePath.len()
                    if moveLen == 0:
                        continue
                    if moveLen >= state.timeLeft:
                        # no point in moving there
                        continue
                    moveOptions.add(MoveOption(playerId: playerId, kind: mkMove, path: movePath))
            else:
                moveOptions.add(MoveOption(playerId: playerId, kind: mkMove, path: pp[1..^1]))
            moveOptionsPerPlayer.add(moveOptions)

        var best = -1
        var res = newSeq[int]()
        if moveOptionsPerPlayer.len() == 1:
            for opt in moveOptionsPerPlayer[0]:
                let n = go(valves, state.apply(opt), allPaths, cache)
                if n > best:
                    best = n
        else:
            assert moveOptionsPerPlayer.len() == 2
            let opts1 = moveOptionsPerPlayer[0]
            let opts2 = moveOptionsPerPlayer[1]
            var pairs = newSeq[(MoveOption, MoveOption)]()

            let (mainOpts, subOpts) = if opts2.len() == 1 and opts2[0].kind == mkOpen:
                (opts2, opts1)
            else:
                (opts1, opts2)

            for opt1 in mainOpts:
                for opt2 in subOpts:
                    if opt1.kind == mkOpen and opt2.kind == mkOpen and opt1.valveId == opt2.valveId:
                        # cannot both open the same valve
                        continue
                    if opt1.kind == mkMove and opt2.kind == mkMove and opt1.path[^1] == opt2.path[^1]:
                        # don't move both to the same target
                        continue
                    if opt1.kind == mkOpen and opt2.kind == mkMove and opt1.valveId == opt2.path[^1]:
                        # don't move to a valve being opened by the other
                        continue
                    if opt2.kind == mkOpen and opt1.kind == mkMove and opt2.valveId == opt1.path[^1]:
                        # don't open a valve being moved to by the other
                        # should not happen given we choose mainOpts and subOpts above
                        assert false, &"opt2.valveId = {opt2.valveId}, opt1.path = {opt1.path}"
                        continue

                    pairs.add((opt1, opt2))
            if pairs.len() == 0:
                for opt1 in opts1:
                    pairs.add((opt1, MoveOption(playerId: 1, kind: mkNothing)))
                for opt2 in opts2:
                    pairs.add((MoveOption(playerId: 0, kind: mkNothing), opt2))
            for (opt1, opt2) in pairs:
                let newState = state.apply(opt1, opt2)
                let n = go(valves, newState, allPaths, cache)
                if n > best:
                    best = n

        if best < 0:
            ret = sumPressuresNow
        else:
            ret = best

    # store delta in cache
    cache[cacheKey] = ret - sumPressuresNow
    return ret


proc newState(valves: Table[string, Valve]): State =
    let openableValveIds = valves.values.toSeq.filterIt(it.flowRate > 0).mapIt(it.id)
    result = State(playerPaths: @[@["AA"]], openValves: initTable[string, int](), timeLeft: 30, openableValveIds: openableValveIds)

proc newStateP2(valves: Table[string, Valve]): State =
    let openableValveIds = valves.values.toSeq.filterIt(it.flowRate > 0).mapIt(it.id)
    result = State(playerPaths: @[@["AA"], @["AA"]], openValves: initTable[string, int](), timeLeft: 26, openableValveIds: openableValveIds)

proc part1(file: string): int =
    let lookup = createLookup(lines(file).toSeq.map(parseLine))
    let initialState = newState(lookup)
    let allPaths = findAllPaths(lookup)
    var cache = initTable[string, int]()
    let before = cpuTime()
    let ret = go(lookup, initialState, allPaths, cache)
    let elapsed = int(1000 * (cpuTime() - before))
    echo &"Part 1: file {file} took {elapsed} ms"
    return ret

proc part2(file: string): int =
    let lookup = createLookup(lines(file).toSeq.map(parseLine))
    let initialState = newStateP2(lookup)
    let allPaths = findAllPaths(lookup)
    var cache = initTable[string, int]()
    let before = cpuTime()
    let ret = go(lookup, initialState, allPaths, cache)
    let elapsed = int(1000 * (cpuTime() - before))
    echo &"Part 2: file {file} took {elapsed} ms"
    return ret

suite "day 16":
    test "parseLine":
        let v = parseLine("Valve AA has flow rate=2; tunnels lead to valves DD, II, BB")
        check(v.id == "AA")
        check(v.flowRate == 2)
        check(v.next == @["DD", "II", "BB"])

    test "part1":
        check(part1("example") == 1651)
        check(part1("input") == 1792)

    test "part2":
        check(part2("example") == 1707)
        check(part2("input") == 2587) # took 934356 ms :(