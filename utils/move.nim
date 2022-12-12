type
  Directions* = enum
    dUp, dRight, dLeft, dDown

let directions* = @[Directions.dUp, Directions.dDown, Directions.dLeft, Directions.dRight]

type Coord* = object
    x*: int
    y*: int

proc move*(c: Coord, dir: Directions): Coord =
    return case dir:
        of Directions.dUp:    Coord(x: c.x, y: c.y - 1)
        of Directions.dDown:  Coord(x: c.x, y: c.y + 1)
        of Directions.dLeft:  Coord(x: c.x - 1, y: c.y)
        of Directions.dRight: Coord(x: c.x + 1, y: c.y)

iterator coordinates*(lines: seq[string]): Coord =
    let columns = lines[0].len()
    for r in 0..<lines.len():
        for c in 0..<columns:
            yield Coord(y: r, x: c)