import sequtils
import strutils
import unittest
import sets
import options
import sugar
import algorithm

type
    CPU = ref object
        X: int
        cycles: int

type
    Instruction = object
        cycles: int
        dx: int

proc newCPU(): CPU = CPU(cycles: 0, X: 1)

proc parseInstr(instr: string): Instruction =
    if instr == "noop":
        return Instruction(cycles: 1, dx: 0)
    elif instr.startsWith("addx"):
        let parts = instr.split(' ')
        return Instruction(cycles: 2, dx: parts[1].parseInt())
    assert(false)

proc execute(c: CPU, i: Instruction): CPU = CPU(X: c.X + i.dx, cycles: c.cycles + i.cycles)

proc signalStrength(instructions: seq[Instruction], idx: int = 0, cpu: CPU = newCPU()): int =
    let instr = instructions[idx]
    let strength = (1..instr.cycles)
        .mapIt(it + cpu.cycles)
        .filterIt((it - 20) mod 40 == 0)
        .foldl(a + (cpu.X * b), 0)
    let newCPU = execute(cpu, instr)
    if newCPU.cycles > 220:
        return strength
    return strength + signalStrength(instructions, idx + 1, newCPU)

proc isSpriteAtPos(cpu: CPU, pos: int): bool = 
    let rowPos = pos mod 40
    return rowPos >= cpu.X - 1 and rowPos <= cpu.X + 1

proc draw(instructions: seq[Instruction]): seq[char] =
    var cpu = newCPU()
    var screen = newSeq[char]()
    for instr in instructions:
        for i in 1..instr.cycles:
            let pos = screen.len()
            screen.add(if isSpriteAtPos(cpu, pos): '#' else: '.')

        cpu = execute(cpu, instr)
        if cpu.cycles >= 40 * 6:
            break
    return screen

proc show(screen: seq[char]) =
    var pos = 0
    for ch in screen:
        stdout.write(ch)
        pos += 1
        if pos mod 40 == 0:
            stdout.write('\n')
    flushFile(stdout)

proc part1(file: string): int =
    let instructions = lines(file).toSeq().map(parseInstr)
    return signalStrength(instructions)

proc part2(file: string): int =
    let instructions = lines(file).toSeq().map(parseInstr)
    let screen = draw(instructions)
    show(screen)
    return 0

suite "day 10":
    test "parseInstr":
        check(parseInstr("noop") == Instruction(cycles: 1, dx: 0))
        check(parseInstr("addx 3") == Instruction(cycles: 2, dx: 3))
        check(parseInstr("addx -5") == Instruction(cycles: 2, dx: -5))

    test "part1":
        check(part1("example") == 13140)
        check(part1("input") == 14780)

    test "part2":
        check(part2("example") == 0)
        echo "--"
        check(part2("input") == 0)