from sequtils import cycle
from tables import len, mvalues, values
import attano.types

proc flatten(e: PExpr): seq[PExpr] =
  case e.kind
  of exprNodeRef:
    assert e.width > 0
    if e.width == 1:
      result = @[e]
    else:
      result.newSeq(e.width)
      for bit in 0 .. e.width-1:
        result[bit] = PExpr(
          loc: e.loc,
          kind: exprSlice,
          sliceUpperBound: bit,
          sliceLowerBound: bit,
          sliceChild: e,
        )
  
  of exprLiteral:
    let zero = PExpr(
      loc: e.loc,
      kind: exprLiteral,
      literalWidth: 1,
      literalValue: 0,
    )
    let one = PExpr(
      loc: e.loc,
      kind: exprLiteral,
      literalWidth: 1,
      literalValue: 1,
    )
    result.newSeq(e.literalWidth)
    for bit in 0 .. e.literalWidth-1:
      result[bit] =
        if (e.literalValue and (1 shl bit)) != 0:
          one
        else:
          zero
  
  of exprDisconnected:
    result = @[e]
  
  of exprConcat:
    result = @[]
    for i in countdown(e.concatChildren.len()-1, 0):
      result.add(flatten(e.concatChildren[i]))
  
  of exprMultiply:
    result = cycle(flatten(e.multiplyChild), e.multiplyCount)
  
  of exprSlice:
    result = flatten(e.sliceChild)[e.sliceLowerBound .. e.sliceUpperBound]

proc flattenNodes*(unit: PCompilationUnit) =
  assert(len(unit.aliases) == 0)
  assert(len(unit.instances) == 0)
  
  for primitiveDef in unit.primitives.values():
    for exp in primitiveDef.pinBindings.mvalues():
      let bitExps = flatten(exp)
      assert(len(bitExps) == 1)
      exp = bitExps[0]
