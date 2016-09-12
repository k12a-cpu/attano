from os import parentDir
from strutils import `%`
import types
import tables

{.compile: "lexer_gen.c".}
{.compile: "parser_gen.c".}
{.passC: ("-I" & parentDir(currentSourcePath())).}

type
  ParseError* = object of Exception

var currentFilename: string
var currentLineno {.header: "lexer_gen.h", importc: "attano_yylineno".}: int

var unit: PCompilationUnit
var composite: PCompositeDef
var device, footprint: string
var pinBindings: OrderedTable[PinNumber, PExpr]
var portWidths: OrderedTable[NodeName, int]
var bindings: OrderedTable[NodeName, PExpr]
var exprStack: seq[PExpr] = @[]

proc reset(theUnit: PCompilationUnit = nil, theFilename: string = "<unknown>") =
  currentFilename = theFilename
  currentLineno = 0
  unit = theUnit
  composite = nil
  device = nil
  footprint = nil
  pinBindings = initOrderedTable[PinNumber, PExpr]()
  portWidths = initOrderedTable[NodeName, int]()
  bindings = initOrderedTable[NodeName, PExpr]()
  exprStack.setLen(0)

proc popn[T](a: var seq[T], count: int): seq[T] {.noSideEffect.} =
  let length = a.len()
  result = a[(length - count) .. (length - 1)]
  a.setLen(length - count)

proc currentLoc(): Loc =
  (filename: currentFilename, lineno: currentLineno)

proc parseError(msg: string) =
  raise newException(ParseError, "parse error at $1: $2" % [$currentLoc(), msg])

proc parseError(msg: cstring) {.cdecl, exportc: "attano_yyerror".} =
  parseError($msg)

proc doCompositeBegin(name: cstring) {.cdecl, exportc: "attano_yy_composite_begin".} =
  composite = PCompositeDef(
    loc: currentLoc(),
    name: $name,
    portWidths: portWidths,
    nodes: initOrderedTable[NodeName, PNodeDef](),
    aliases: initOrderedTable[NodeName, PAliasDef](),
    primitives: initOrderedTable[InstanceName, PPrimitiveDef](),
    instances: initOrderedTable[InstanceName, PInstanceDef](),
  )
  portWidths = initOrderedTable[NodeName, int]()

proc doCompositeEnd() {.cdecl, exportc: "attano_yy_composite_end".} =
  unit.composites[composite.name] = composite
  composite = nil

proc doNode(name: cstring, width: uint64) {.cdecl, exportc: "attano_yy_node".} =
  let nodeDef = PNodeDef(
    loc: currentLoc(),
    name: $name,
    width: int(width),
  )
  if composite == nil:
    unit.nodes[nodeDef.name] = nodeDef
  else:
    composite.nodes[nodeDef.name] = nodeDef

proc doAlias(name: cstring) {.cdecl, exportc: "attano_yy_alias".} =
  let aliasDef = PAliasDef(
    loc: currentLoc(),
    name: $name,
    value: exprStack.pop(),
  )
  if composite == nil:
    unit.aliases[aliasDef.name] = aliasDef
  else:
    composite.aliases[aliasDef.name] = aliasDef

proc doInstance(name, compositeName: cstring) {.cdecl, exportc: "attano_yy_instance".} =
  let instanceDef = PInstanceDef(
    loc: currentLoc(),
    name: $name,
    compositeName: $compositeName,
    bindings: bindings,
  )
  if composite == nil:
    unit.instances[instanceDef.name] = instanceDef
  else:
    composite.instances[instanceDef.name] = instanceDef
  bindings = initOrderedTable[NodeName, PExpr]()

proc doPrimitive(name: cstring) {.cdecl, exportc: "attano_yy_primitive".} =
  let primitiveDef = PPrimitiveDef(
    loc: currentLoc(),
    name: $name,
    device: device,
    footprint: footprint,
    pinBindings: pinBindings,
  )
  if composite == nil:
    unit.primitives[primitiveDef.name] = primitiveDef
  else:
    composite.primitives[primitiveDef.name] = primitiveDef
  device = nil
  footprint = nil
  pinBindings = initOrderedTable[PinNumber, PExpr]()

proc doDevice(dev: cstring) {.cdecl, exportc: "attano_yy_device".} =
  device = $dev

proc doFootprint(fp: cstring) {.cdecl, exportc: "attano_yy_footprint".} =
  footprint = $fp

proc doPin(number: uint64) {.cdecl, exportc: "attano_yy_pin".} =
  pinBindings[PinNumber(number)] = exprStack.pop()

proc doPort(name: cstring, width: uint64) {.cdecl, exportc: "attano_yy_port".} =
  portWidths[$name] = int(width)

proc doBinding(name: cstring) {.cdecl, exportc: "attano_yy_binding".} =
  bindings[$name] = exprStack.pop()

proc doExprNodeRef(name: cstring) {.cdecl, exportc: "attano_yy_expr_noderef".} =
  exprStack.add(PExpr(
    loc: currentLoc(),
    kind: exprNodeRef,
    node: $name,
    width: -1,
  ))

proc doExprLiteral(width, value: uint64) {.cdecl, exportc: "attano_yy_expr_literal".} =
  exprStack.add(PExpr(
    loc: currentLoc(),
    kind: exprLiteral,
    literalWidth: int(width),
    literalValue: int(value),
  ))

proc doExprDisconnected() {.cdecl, exportc: "attano_yy_expr_disconnected".} =
  exprStack.add(PExpr(
    loc: currentLoc(),
    kind: exprDisconnected,
  ))

proc doExprConcat(numChildren: uint64) {.cdecl, exportc: "attano_yy_expr_concat".} =
  let children = exprStack.popn(int(numChildren))
  exprStack.add(PExpr(
    loc: currentLoc(),
    kind: exprConcat,
    concatChildren: children,
  ))

proc doExprMultiply(count: uint64) {.cdecl, exportc: "attano_yy_expr_multiply".} =
  let child = exprStack.pop()
  exprStack.add(PExpr(
    loc: currentLoc(),
    kind: exprMultiply,
    multiplyCount: int(count),
    multiplyChild: child,
  ))

proc doExprSlice(upperBound, lowerBound: uint64) {.cdecl, exportc: "attano_yy_expr_slice".} =
  let child = exprStack.pop()
  exprStack.add(PExpr(
    loc: currentLoc(),
    kind: exprSlice,
    sliceUpperBound: int(upperBound),
    sliceLowerBound: int(lowerBound),
    sliceChild: child,
  ))

proc parseStdinInternal() {.cdecl, header: "parser.h", importc: "attano_parse_stdin".}
proc parseFileInternal(filename: cstring) {.cdecl, header: "parser.h", importc: "attano_parse_file".}

proc parseStdin*(unit: PCompilationUnit) =
  ## Parse Attano directives from stdin and add them to `unit`.
  reset(unit, "<stdin>")
  parseStdinInternal()
  reset()

proc parseFile*(unit: PCompilationUnit, filename: string) =
  ## Parse Attano directives from the given file and add them to `unit`.
  reset(unit, filename)
  parseFileInternal(filename)
  reset()

proc parseStdin*(): PCompilationUnit =
  ## Parse Attano directives from stdin and return a new PCompilationUnit
  ## containing them.
  result = newCompilationUnit()
  parseStdin(result)

proc parseFile*(filename: string): PCompilationUnit =
  ## Parse Attano directives from the given file and return a new
  ## PCompilationUnit containing them.
  result = newCompilationUnit()
  parseFile(result, filename)
