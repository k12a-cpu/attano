from tables import pairs, values
from strutils import split, toHex
import ropes
import types
import tables

type
  DeviceSpec = object
    module: string
    ports: seq[string]

include svdevices

proc normalise(s: string): string {.noSideEffect.} =
  const wordChars = {'A' .. 'Z'} + {'a' .. 'z'} + {'0' .. '9'} + {'_'}
  result = ""
  for c in s:
    if c in wordChars:
      result.add(c)
    elif c == '.':
      result.add("__")
    else:
      assert false, "unexpected character in node or instance name: " & $c

proc rope(loc: Loc): Rope =
  rope($loc)

proc rope(e: PExpr): Rope =
  case e.kind
  of exprNodeRef:
    result = rope(normalise(e.node))
  of exprLiteral:
    result = rope(e.literalWidth) & rope("'d") & rope(e.literalValue)
  of exprDisconnected:
    result = rope("1'bx")
  of exprConcat:
    result = rope("{")
    if len(e.concatChildren) > 0:
      result = result & rope(e.concatChildren[0])
      for child in e.concatChildren[1 .. high(e.concatChildren)]:
        result = result & rope(", ") & rope(child)
    result = result & rope("}")
  of exprMultiply:
    result = &[
      rope("{"),
      rope(e.multiplyCount),
      rope("{"),
      rope(e.multiplyChild),
      rope("}}"),
    ]
  of exprSlice:
    if e.sliceUpperBound == e.sliceLowerBound:
      result = &[
        rope(e.sliceChild),
        rope("["),
        rope(e.sliceUpperBound),
        rope("]"),
      ]
    else:
      result = &[
        rope(e.sliceChild),
        rope("["),
        rope(e.sliceUpperBound),
        rope(":"),
        rope(e.sliceLowerBound),
        rope("]"),
      ]

proc rope(nodeDef: PNodeDef): Rope =
  result = rope("logic ")
  if nodeDef.width != 1:
    result = &[result, rope("["), rope(nodeDef.width-1), rope(":0] ")]
  result = &[result, rope(normalise(nodeDef.name)), rope(";\n")]

proc rope(primitiveDef: PPrimitiveDef): Rope =
  let spec = devices[primitiveDef.device]

  result = &[
    rope(spec.module),
    rope(" "),
    rope(normalise(primitiveDef.name)),
    rope("("),
  ]
  var first = true
  for pin, exp in primitiveDef.pinBindings:
    if first:
      first = false
    else:
      result = result & rope(",")
    result = &[
      result,
      rope("\n  ."),
      rope(spec.ports[pin-1]),
      rope("("),
      rope(exp),
      rope(")"),
    ]
  result = result & rope("\n);\n")

proc rope(unit: PCompilationUnit): Rope =
  for nodeDef in unit.nodes.values():
    result = result & rope(nodeDef)
  for primitiveDef in unit.primitives.values():
    result = result & rope(primitiveDef)

proc toSV*(unit: PCompilationUnit): string =
  $rope(unit)
