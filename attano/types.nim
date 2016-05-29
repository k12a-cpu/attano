from strutils import `%`

type
  Loc* = tuple
    filename: string
    lineno: int

proc `$`*(loc: Loc): string {.noSideEffect.} =
  "$1:$2" % [loc.filename, $loc.lineno]
