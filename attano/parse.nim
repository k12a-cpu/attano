from os import parentDir
from strutils import `%`
import attano.types

{.compile: "lexer_gen.c".}
{.compile: "parser_gen.c".}
{.passC: ("-I" & parentDir(currentSourcePath())).}

type
  ParseError = object of Exception

var currentFilename: string
var currentLineno {.header: "lexer_gen.h", importc: "attano_yylineno".}: int

proc reset() =
  discard

proc currentLoc(): Loc =
  (filename: currentFilename, lineno: currentLineno)

proc parseError(msg: string) =
  raise newException(ParseError, "parse error at $1: $2" % [$currentLoc(), msg])

proc parseError(msg: cstring) {.cdecl, exportc: "attano_yyerror".} =
  parseError($msg)

proc parseStdinInternal() {.cdecl, header: "parser.h", importc: "attano_parse_stdin".}
proc parseFileInternal(filename: cstring) {.cdecl, header: "parser.h", importc: "attano_parse_file".}

proc parseStdin*() =
  reset()
  currentFilename = "<stdin>"
  parseStdinInternal()
  reset()

proc parseFile*(filename: string) =
  reset()
  currentFilename = filename
  parseFileInternal(filename)
  reset()
