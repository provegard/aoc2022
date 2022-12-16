import options

iterator slidingWindow*[T](s: seq[T], size: int): (seq[T], int) =
    for i in size..s.len():
        let chunk = s[(i-size)..(i-1)]
        yield (chunk, i)

proc doOpt*[T](opt: Option[T], action: proc (x: T): void) =
    if opt.isSome:
        action(opt.get)

proc skip*[T](s: seq[T], n: int): seq[T] = s[n..<s.len()]

proc flatMap*[X, Y](enumerable: seq[X], mapper: proc (x: X): seq[Y]): seq[Y] =
  result = newSeq[Y]()
  for x in enumerable:
    for y in mapper(x):
      result &= y

proc minByIdx*[T, U](s: seq[T], f: proc (a: T, b: U): int, arg: U): int =
    var cur = 0
    for i in 1..<s.len():
        if f(s[i], arg) < f(s[cur], arg):
            cur = i
    return cur