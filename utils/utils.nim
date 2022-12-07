iterator slidingWindow*[T](s: seq[T], size: int): (seq[T], int) =
    for i in size..s.len():
        let chunk = s[(i-size)..(i-1)]
        yield (chunk, i)

type
    Point2D* = object
        x*, y*: int

proc manhattan*(a, b: Point2D): int =
    return abs(a.x - b.x) - abs(a.y - b.y)