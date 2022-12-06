iterator slidingWindow*[T](s: seq[T], size: int): (seq[T], int) =
    for i in size..s.len():
        let chunk = s[(i-size)..(i-1)]
        yield (chunk, i)