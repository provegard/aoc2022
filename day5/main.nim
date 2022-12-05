import std/sequtils
import std/strutils
import std/unittest
import std/sets
import std/options
import sugar
import algorithm

type Stack = ref object of RootObj
    crates: seq[char]

type Stacks = seq[Stack]

type MoveInstruction = ref object of RootObj
    count: int
    source: int # 1-based
    target: int # 1-based

proc `==`(a, b: MoveInstruction): bool =
    return a.count == b.count and a.source == b.source and a.target == b.target

proc `==`(a, b: Stack): bool =
    return a.crates == b.crates

type MoveInstructions = seq[MoveInstruction]

method execute(self: MoveInstruction, stacks: Stacks) {.base.} =
    proc exec1(stackss: Stacks) =
        var src = stackss[self.source - 1]
        var tgt = stackss[self.target - 1]
        let item = src.crates.pop()
        tgt.crates.add(item)

    var stacksCopy = stacks
    for i in 1..self.count:
        exec1(stacksCopy)

method executeMulti(self: MoveInstruction, stacks: Stacks) {.base.} =
    var src = stacks[self.source - 1]
    var tgt = stacks[self.target - 1]

    let slice = (src.crates.len() - self.count)..<src.crates.len()

    let items = src.crates[slice]
    tgt.crates.add(items)
    src.crates.delete(slice)

proc top(stacks: Stacks): string =
    return stacks.mapIt(if it.crates.len() > 0: $it.crates[^1] else: "").join()

proc parseInstruction(ins: string): MoveInstruction =
    let parts = ins.split(' ')
    return MoveInstruction(count: parts[1].parseInt(), source: parts[3].parseInt(), target: parts[5].parseInt())

proc parseStacks(lines: seq[string]): Stacks =
    let count = (lines[0].len() + 1) div 4 # could also read numbers line...
    var revLines = lines
    revLines.reverse()
    revLines.delete(0) # delete numbers

    var stacks = newSeq[Stack](count)
    for i in 0..(count-1):
        stacks[i] = Stack(crates: newSeq[char]())

    for line in revLines:
        for c in 0..(count-1):
            var crate = line[1 + 4 * c]
            if crate != ' ':
                stacks[c].crates.add(crate)
    return stacks

proc parseLines(ll: seq[string]): (Stacks, MoveInstructions) =
    var stackLines = newSeq[string]()
    var moveInstructions = newSeq[MoveInstruction]()
    var collectingStackLines = true
    for line in ll:
        if line == "":
            collectingStackLines = false
        elif collectingStackLines:
            stackLines.add(line)
        else:
            moveInstructions.add(parseInstruction(line))
    
    return (parseStacks(stackLines), moveInstructions)

proc part(file: string, insExec: (ins: MoveInstruction, stacks: var Stacks) -> void): string =
    let (stacks, instructions) = parseLines(lines(file).toSeq())
    var stacksCopy = stacks
    for ins in instructions:
        insExec(ins, stacksCopy)
    return top(stacksCopy)    

proc part1(file: string): string = part(file, (ins: MoveInstruction, stacks: var Stacks) => ins.execute(stacks))

proc part2(file: string): string = part(file, (ins: MoveInstruction, stacks: var Stacks) => ins.executeMulti(stacks))

suite "day 5":
    test "MoveInstruction.execute":
        let stack1 = Stack(crates: @['A'])
        let stack2 = Stack(crates: newSeq[char]())

        let ins = MoveInstruction(count: 1, source: 1, target: 2)
        ins.execute(@[stack1, stack2])

        check(stack1.crates == newSeq[char]())
        check(stack2.crates == @['A'])

    test "MoveInstruction.execute 2":
        let stack1 = Stack(crates: @['A', 'B'])
        let stack2 = Stack(crates: newSeq[char]())

        let ins = MoveInstruction(count: 1, source: 1, target: 2)
        ins.execute(@[stack1, stack2])

        check(stack1.crates == @['A'])
        check(stack2.crates == @['B'])

    test "MoveInstruction.execute many":
        let stack1 = Stack(crates: @['A', 'B'])
        let stack2 = Stack(crates: newSeq[char]())

        let ins = MoveInstruction(count: 2, source: 1, target: 2)
        ins.execute(@[stack1, stack2])

        check(stack1.crates == newSeq[char]())
        check(stack2.crates == @['B', 'A'])

    test "MoveInstruction.execute many, multi":
        let stack1 = Stack(crates: @['A', 'B', 'C'])
        let stack2 = Stack(crates: newSeq[char]())

        let ins = MoveInstruction(count: 2, source: 1, target: 2)
        ins.executeMulti(@[stack1, stack2])

        check(stack1.crates == @['A'])
        check(stack2.crates == @['B', 'C'])

    test "MoveInstruction.execute 3":
        let stack1 = Stack(crates: @['X'])
        let stack2 = Stack(crates: @['A', 'B'])
        let stack3 = Stack(crates: newSeq[char]())
        let stack4 = Stack(crates: @['Y'])

        let ins = MoveInstruction(count: 1, source: 2, target: 3)
        ins.execute(@[stack1, stack2, stack3, stack4])

        check(stack1.crates == @['X'])
        check(stack2.crates == @['A'])
        check(stack3.crates == @['B'])
        check(stack4.crates == @['Y'])

    test "parseInstruction":
        check(parseInstruction("move 3 from 1 to 2") == MoveInstruction(count: 3, source: 1, target: 2))

    test "parseStacks":
        let ll = @[
            "    [D]    ",
            "[N] [C]    ",
            "[Z] [M] [P]",
            " 1   2   3"
        ]
        let stacks = parseStacks(ll)
        check(stacks == @[
            Stack(crates: @['Z', 'N']),
            Stack(crates: @['M', 'C', 'D']),
            Stack(crates: @['P']),
        ])

    test "top":
        let stacks = @[
            Stack(crates: @['A', 'B']),
            Stack(crates: @['C', 'D']),
            Stack(crates: newSeq[char]()),
        ]
        check(top(stacks) == "BD")

    test "part1":
        check(part1("example") == "CMZ")
        check(part1("input") == "SBPQRSCDF")

    test "part2":
        check(part2("example") == "MCD")
        check(part2("input") == "RGLVRCQSB")