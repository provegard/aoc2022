import sequtils
import strutils
import unittest
import sets
import options
import sugar
import algorithm
import ../utils/utils

type
    File = ref object of RootObj
        size: int
        name: string

type
    Directory = ref object of RootObj
        name: string
        files: seq[File]
        dirs: seq[Directory]

proc getSizeRecursive(dir: Directory): int =
    let fileSize = foldl(dir.files, a + b.size, 0)
    let dirSize = foldl(dir.dirs, a + getSizeRecursive(b), 0)
    return fileSize + dirSize

proc newDir(name: string): Directory =
    return Directory(name: name, files: newSeq[File](), dirs: newSeq[Directory]())

proc newFile(name: string, size: int): File =
    return File(name: name, size: size)

proc parse(lines: seq[string]): Directory =
    var stack = newSeq[Directory]()

    for line in lines:
        if line.startsWith("$ cd"):
            let dirname = line[5..^1]
            if dirname == "..":
                discard stack.pop()
            else:
                let dir = newDir(dirname)

                # Add as sub dir to current
                if stack.len() > 0:
                    let cur = stack[^1]
                    cur.dirs.add(dir)

                stack.add(dir)
        elif line != "$ ls":
            let parts = line.split(' ')
            if parts[0] == "dir":
                # sub dir
                # ignore - handle when cd:ing into it
                discard
            else:
                let size = parts[0].parseInt()
                let name = parts[1]
                let file = newFile(name, size)

                # Add to current dir
                let curDir = stack[^1]
                curDir.files.add(file)
    return stack[0]

proc visitDirs[T](tree: Directory, visitor: (Directory, T) -> T, seed: T): T =
    var t = visitor(tree, seed)
    for dir in tree.dirs:
        t = visitDirs(dir, visitor, t)
    return t

proc part1(file: string): int =
    let ll = lines(file).toSeq()
    let tree = parse(ll)

    let maxSize = 100000

    let total = visitDirs(tree, proc (d: Directory, size: int): int =
        let s = getSizeRecursive(d)
        if s <= maxSize:
            return size + s
        return size
    , 0)

    return total

proc part2(file: string): int =
    let ll = lines(file).toSeq()
    let tree = parse(ll)

    let totalSize = 70000000
    let unusedNeeded = 30000000
    let unused = totalSize - getSizeRecursive(tree)

    var candidateSizes = visitDirs(tree, proc (d: Directory, list: seq[int]): seq[int] =
        let s = getSizeRecursive(d)
        if s + unused >= unusedNeeded:
            return concat(list, @[s])
        return list
    , newSeq[int]())

    candidateSizes.sort(SortOrder.Ascending)

    return candidateSizes[0]

suite "day 7":
    test "part 1":
        check(part1("example") == 95437)
        check(part1("input") == 1350966)

    test "part 2":
        check(part2("example") == 24933642)
        check(part2("input") == 6296435)
