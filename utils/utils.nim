import options

iterator slidingWindow*[T](s: seq[T], size: int): (seq[T], int) =
    for i in size..s.len():
        let chunk = s[(i-size)..(i-1)]
        yield (chunk, i)

type
    Point2D* = object
        x*, y*: int

proc manhattan*(a, b: Point2D): int =
    return abs(a.x - b.x) - abs(a.y - b.y)

proc doOpt*[T](opt: Option[T], action: proc (x: T): void) =
    if opt.isSome:
        action(opt.get)

proc skip*[T](s: seq[T], n: int): seq[T] = s[n..<s.len()]