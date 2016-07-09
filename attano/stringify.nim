from tables import pairs, values
import ropes
import types

proc rope*(loc: Loc): Rope =
  rope($loc)

proc rope*(e: PExpr): Rope =
  case e.kind
  of exprNodeRef:
    result = rope(e.node)
  of exprLiteral:
    result = rope(e.literalWidth) & rope("'d") & rope(e.literalValue)
  of exprDisconnected:
    result = rope("disconnected")
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
      rope(" x "),
      rope(e.multiplyChild),
      rope("}"),
    ]
  of exprSlice:
    result = &[
      rope(e.sliceChild),
      rope("["),
      rope(e.sliceUpperBound),
      rope(":"),
      rope(e.sliceLowerBound),
      rope("]"),
    ]

proc rope*(nodeDef: PNodeDef, indent: Rope = nil): Rope =
  &[
    indent,
    rope("node "),
    rope(nodeDef.name),
    rope(": bits["),
    rope(nodeDef.width),
    rope("];\n"),
  ]

proc rope*(aliasDef: PAliasDef, indent: Rope = nil): Rope =
  &[
    indent,
    rope("alias "),
    rope(aliasDef.name),
    rope(" = "),
    rope(aliasDef.value),
    rope(";\n")
  ]

proc rope*(primitiveDef: PPrimitiveDef, indent: Rope = nil): Rope =
  result = &[
    indent,
    rope("primitive "),
    rope(primitiveDef.name),
    rope(" (\n"),
    indent,
    rope("  device \""),
    rope(primitiveDef.device),
    rope("\";\n"),
    indent,
    rope("  footprint \""),
    rope(primitiveDef.footprint),
    rope("\";\n"),
  ]
  for pin, exp in primitiveDef.pinBindings:
    result = &[
      result,
      indent,
      rope("  pin "),
      rope(pin),
      rope(" => "),
      rope(exp),
      rope(";\n"),
    ]
  result = result & indent & rope(");\n")

proc rope(instanceDef: PInstanceDef, indent: Rope = nil): Rope =
  result = &[
    indent,
    rope("instance "),
    rope(instanceDef.name),
    rope(": "),
    rope(instanceDef.compositeName),
    rope(" (\n"),
  ]
  for node, exp in instanceDef.bindings:
    result = &[
      result,
      indent,
      rope("  "),
      rope(node),
      rope(" => "),
      rope(exp),
      rope(",\n"),
    ]
  result = result & indent & rope(");\n")

proc rope(compositeDef: PCompositeDef): Rope =
  result = &[
    rope("composite "),
    rope(compositeDef.name),
    rope(" (\n"),
  ]
  for port, width in compositeDef.portWidths:
    result = &[
      result,
      rope("  "),
      rope(port),
      rope(": bits["),
      rope(width),
      rope("],\n"),
    ]
  result = result & rope(") {\n")
  let indent = rope("  ")
  for nodeDef in compositeDef.nodes.values():
    result = result & rope(nodeDef, indent)
  for aliasDef in compositeDef.aliases.values():
    result = result & rope(aliasDef, indent)
  for primitiveDef in compositeDef.primitives.values():
    result = result & rope(primitiveDef, indent)
  for instanceDef in compositeDef.instances.values():
    result = result & rope(instanceDef, indent)
  result = result & rope("}\n")

proc rope(unit: PCompilationUnit): Rope =
  for compositeDef in unit.composites.values():
    result = result & rope(compositeDef)
  for nodeDef in unit.nodes.values():
    result = result & rope(nodeDef)
  for aliasDef in unit.aliases.values():
    result = result & rope(aliasDef)
  for primitiveDef in unit.primitives.values():
    result = result & rope(primitiveDef)
  for instanceDef in unit.instances.values():
    result = result & rope(instanceDef)

proc `$`*(unit: PCompilationUnit): string =
  $rope(unit)
