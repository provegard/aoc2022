type
  Directions* = enum
    dUp, dRight, dLeft, dDown

let directions* = @[Directions.dUp, Directions.dDown, Directions.dLeft, Directions.dRight]

type Coord* = (int, int)

proc move*(c: Coord, dir: Directions): Coord =
    return case dir:
        of Directions.dUp:    (c[0] - 1, c[1])
        of Directions.dDown:  (c[0] + 1, c[1]) 
        of Directions.dLeft:  (c[0], c[1] - 1) 
        of Directions.dRight: (c[0], c[1] + 1)