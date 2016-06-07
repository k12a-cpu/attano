import tables
import attano.types

proc dereference(e: PExpr, unit: PCompilationUnit): PExpr =
  case e.kind
  of exprNodeRef:
    result =
      if e.node in unit.aliases:
        unit.aliases[e.node].value.dereference(unit)
      else:
        e
  of exprLiteral:
    result = e
  of exprConcat:
    var newChildren = newSeq[PExpr](e.concatChildren.len())
    for i, child in e.concatChildren:
      newChildren[i] = child.dereference(unit)
    result = PExpr(
      loc: e.loc,
      kind: exprConcat,
      concatChildren: newChildren,
    )
  of exprMultiply:
    result = PExpr(
      loc: e.loc,
      kind: exprMultiply,
      multiplyCount: e.multiplyCount,
      multiplyChild: e.multiplyChild.dereference(unit),
    )
  of exprSlice:
    result = PExpr(
      loc: e.loc,
      kind: exprSlice,
      sliceUpperBound: e.sliceUpperBound,
      sliceLowerBound: e.sliceLowerBound,
      sliceChild: e.sliceChild.dereference(unit),
    )

proc dereference*(unit: PCompilationUnit) =
  for primitiveDef in unit.primitives.values():
    for pin, exp in primitiveDef.pinBindings.mpairs():
      exp = exp.dereference(unit)
  
  #unit.aliases.clear()
  unit.aliases = initOrderedTable[NodeName, PAliasDef]()
