from os import parentDir
from strutils import `%`
import attano.types
import tables

{.compile: "lexer_gen.c".}
{.compile: "parser_gen.c".}
{.passC: ("-I" & parentDir(currentSourcePath())).}

type
  ParseError* = object of Exception

var currentFilename: string
var currentLineno {.header: "lexer_gen.h", importc: "attano_yylineno".}: int

var unit: CompilationUnitRef
var primitive: PrimitiveRef
var composite: CompositeRef
var portWidths: OrderedTable[NodeName, NumBits]
var bindings: OrderedTable[NodeName, ExprRef]
var exprStack: seq[ExprRef] = @[]

proc reset() =
  unit.new()
  unit.nodeWidths = initOrderedTable[NodeName, NumBits]()
  unit.aliases = initOrderedTable[NodeName, ExprRef]()
  unit.primitives = initOrderedTable[ComponentName, PrimitiveRef]()
  unit.composites = initOrderedTable[ComponentName, CompositeRef]()
  unit.instances = @[]
  primitive = nil
  composite = nil
  portWidths = initOrderedTable[NodeName, NumBits]()
  bindings = initOrderedTable[NodeName, ExprRef]()
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

proc beginPrimitive(name: cstring) {.cdecl, exportc: "attano_yy_begin_primitive".} =
  primitive = PrimitiveRef(
    loc: currentLoc(),
    name: $name,
    portWidths: portWidths,
    device: nil,
    footprint: nil,
    pinMapping: initOrderedTable[int, ExprRef](),
  )
  portWidths = initOrderedTable[NodeName, NumBits]()

proc endPrimitive() {.cdecl, exportc: "attano_yy_end_primitive".} =
  unit.primitives[primitive.name] = primitive
  primitive = nil

proc setDevice(device: cstring) {.cdecl, exportc: "attano_yy_set_device".} =
  primitive.device = $device

proc setFootprint(footprint: cstring) {.cdecl, exportc: "attano_yy_set_footprint".} =
  primitive.footprint = $footprint

proc addPinMapping(pin: uint64) {.cdecl, exportc: "attano_yy_add_pin_mapping".} =
  primitive.pinMapping[int(pin)] = exprStack.pop()

proc beginComposite(name: cstring) {.cdecl, exportc: "attano_yy_begin_composite".} =
  composite = CompositeRef(
    loc: currentLoc(),
    name: $name,
    portWidths: portWidths,
    nodeWidths: initOrderedTable[NodeName, NumBits](),
    instances: @[],
  )
  portWidths = initOrderedTable[NodeName, NumBits]()

proc endComposite() {.cdecl, exportc: "attano_yy_end_composite".} =
  unit.composites[composite.name] = composite
  composite = nil

proc constructInstance(instName, compName: cstring) {.cdecl, exportc: "attano_yy_construct_instance".} =
  let instance = InstanceRef(
    loc: currentLoc(),
    name: $instName,
    componentName: $compName,
    bindings: bindings,
  )
  if composite != nil:
    composite.instances.add(instance)
  else:
    unit.instances.add(instance)
  bindings = initOrderedTable[NodeName, ExprRef]()

proc constructNode(name: cstring, width: uint64) {.cdecl, exportc: "attano_yy_construct_node".} =
  if composite != nil:
    composite.nodeWidths[$name] = NumBits(width)
  else:
    unit.nodeWidths[$name] = NumBits(width)

proc constructAlias(name: cstring) {.cdecl, exportc: "attano_yy_construct_alias".} =
  unit.aliases[$name] = exprStack.pop()

proc constructPort(name: cstring, width: uint64) {.cdecl, exportc: "attano_yy_construct_port".} =
  portWidths[$name] = NumBits(width)

proc constructBinding(name: cstring) {.cdecl, exportc: "attano_yy_construct_binding".} =
  bindings[$name] = exprStack.pop()

proc constructExprNodeRef(name: cstring) {.cdecl, exportc: "attano_yy_construct_expr_noderef".} =
  exprStack.add(ExprRef(
    loc: currentLoc(),
    kind: exprNodeRef,
    node: $name,
  ))

proc constructExprLiteral(width, value: uint64) {.cdecl, exportc: "attano_yy_construct_expr_literal".} =
  exprStack.add(ExprRef(
    loc: currentLoc(),
    kind: exprLiteral,
    literalWidth: int(width),
    literalValue: int(value),
  ))

proc constructExprConcat(numChildren: uint64) {.cdecl, exportc: "attano_yy_construct_expr_concat".} =
  let children = exprStack.popn(int(numChildren))
  exprStack.add(ExprRef(
    loc: currentLoc(),
    kind: exprConcat,
    concatChildren: children,
  ))

proc constructExprMultiply(count: uint64) {.cdecl, exportc: "attano_yy_construct_expr_multiply".} =
  let child = exprStack.pop()
  exprStack.add(ExprRef(
    loc: currentLoc(),
    kind: exprMultiply,
    multiplyCount: int(count),
    multiplyChild: child,
  ))

proc constructExprSlice(upperBound, lowerBound: uint64) {.cdecl, exportc: "attano_yy_construct_expr_slice".} =
  let child = exprStack.pop()
  exprStack.add(ExprRef(
    loc: currentLoc(),
    kind: exprSlice,
    sliceUpperBound: int(upperBound),
    sliceLowerBound: int(lowerBound),
    sliceChild: child,
  ))

proc parseStdinInternal() {.cdecl, header: "parser.h", importc: "attano_parse_stdin".}
proc parseFileInternal(filename: cstring) {.cdecl, header: "parser.h", importc: "attano_parse_file".}

proc parseStdin*(): CompilationUnitRef =
  reset()
  currentFilename = "<stdin>"
  parseStdinInternal()
  result = unit
  reset()

proc parseFile*(filename: string): CompilationUnitRef =
  reset()
  currentFilename = filename
  parseFileInternal(filename)
  result = unit
  reset()
