from strutils import `%`
import tables

type
  Loc* = tuple
    filename: string
    lineno: int

  CompositeName* = string
  InstanceName* = string
  NodeName* = string
  PinNumber* = int

  ExprKind* = enum
    exprNodeRef
    exprLiteral
    exprDisconnected
    exprConcat
    exprMultiply
    exprSlice

  Expr* = object
    loc*: Loc
    case kind*: ExprKind
    of exprNodeRef:
      node*: NodeName
      width*: int
    of exprLiteral:
      literalWidth*: int
      literalValue*: int
    of exprDisconnected:
      discard # no fields
    of exprConcat:
      concatChildren*: seq[ref Expr]
    of exprMultiply:
      multiplyCount*: int
      multiplyChild*: ref Expr
    of exprSlice:
      sliceUpperBound*: int
      sliceLowerBound*: int
      sliceChild*: ref Expr

  NodeDef* = object
    loc*: Loc
    name*: NodeName
    width*: int

  AliasDef* = object
    loc*: Loc
    name*: NodeName
    value*: ref Expr

  PrimitiveDef* = object
    loc*: Loc
    name*: InstanceName
    device*: string
    footprint*: string
    pinBindings*: OrderedTable[PinNumber, ref Expr]

  InstanceDef* = object
    loc*: Loc
    name*: InstanceName
    compositeName*: CompositeName
    bindings*: OrderedTable[NodeName, ref Expr]

  CompositeDef* = object
    loc*: Loc
    name*: CompositeName
    portWidths*: OrderedTable[NodeName, int]
    nodes*: OrderedTable[NodeName, ref NodeDef]
    aliases*: OrderedTable[NodeName, ref AliasDef]
    primitives*: OrderedTable[InstanceName, ref PrimitiveDef]
    instances*: OrderedTable[InstanceName, ref InstanceDef]

  CompilationUnit* = object
    composites*: OrderedTable[CompositeName, ref CompositeDef]
    nodes*: OrderedTable[NodeName, ref NodeDef]
    aliases*: OrderedTable[NodeName, ref AliasDef]
    primitives*: OrderedTable[InstanceName, ref PrimitiveDef]
    instances*: OrderedTable[InstanceName, ref InstanceDef]

  PExpr* = ref Expr
  PNodeDef* = ref NodeDef
  PAliasDef* = ref AliasDef
  PPrimitiveDef* = ref PrimitiveDef
  PInstanceDef* = ref InstanceDef
  PCompositeDef* = ref CompositeDef
  PCompilationUnit* = ref CompilationUnit

proc `$`*(loc: Loc): string {.noSideEffect.} =
  "$1:$2" % [loc.filename, $loc.lineno]

proc newCompilationUnit*(): PCompilationUnit not nil {.noSideEffect.} =
  result.new()
  result.composites = initOrderedTable[CompositeName, PCompositeDef]()
  result.nodes = initOrderedTable[NodeName, PNodeDef]()
  result.aliases = initOrderedTable[NodeName, PAliasDef]()
  result.primitives = initOrderedTable[InstanceName, PPrimitiveDef]()
  result.instances = initOrderedTable[InstanceName, PInstanceDef]()
