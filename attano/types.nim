from strutils import `%`
import tables

type
  Loc* = tuple
    filename: string
    lineno: int
  
  ComponentName* = string
  InstanceName* = string
  NodeName* = string
  NumBits* = int
  
  ExprKind* = enum
    exprNodeRef
    exprLiteral
    exprConcat
    exprMultiply
    exprSlice
  
  Expr* = object
    loc*: Loc
    case kind*: ExprKind
    of exprNodeRef:
      node*: NodeName
    of exprLiteral:
      literalWidth*: NumBits
      literalValue*: int
    of exprConcat:
      concatChildren*: seq[ref Expr]
    of exprMultiply:
      multiplyCount*: int
      multiplyChild*: ref Expr
    of exprSlice:
      sliceUpperBound*: NumBits
      sliceLowerBound*: NumBits
      sliceChild*: ref Expr
  
  Instance* = object
    loc*: Loc
    name*: InstanceName
    componentName*: ComponentName
    bindings*: OrderedTable[NodeName, ref Expr]
  
  Primitive* = object
    loc*: Loc
    name*: ComponentName
    portWidths*: OrderedTable[NodeName, NumBits]
    device*: string
    footprint*: string
    pinMapping*: OrderedTable[int, ref Expr]
  
  Composite* = object
    loc*: Loc
    name*: ComponentName
    portWidths*: OrderedTable[NodeName, NumBits]
    nodeWidths*: OrderedTable[NodeName, NumBits]
    instances*: seq[ref Instance]
  
  CompilationUnit* = object
    nodeWidths*: OrderedTable[NodeName, NumBits]
    aliases*: OrderedTable[NodeName, ref Expr]
    primitives*: OrderedTable[ComponentName, ref Primitive]
    composites*: OrderedTable[ComponentName, ref Composite]
    instances*: seq[ref Instance]
  
  ExprRef* = ref Expr
  InstanceRef* = ref Instance
  PrimitiveRef* = ref Primitive
  CompositeRef* = ref Composite
  CompilationUnitRef* = ref CompilationUnit

proc `$`*(loc: Loc): string {.noSideEffect.} =
  "$1:$2" % [loc.filename, $loc.lineno]
