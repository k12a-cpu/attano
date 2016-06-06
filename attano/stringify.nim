from tables import pairs, values
import ropes
import attano.types

proc rope*(loc: Loc): Rope =
  rope($loc)

proc rope*(e: ExprRef): Rope =
  case e.kind
  of exprNodeRef:
    result = rope(e.node)
  of exprLiteral:
    result = rope(e.literalWidth) & rope("'d") & rope(e.literalValue)
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

proc rope*(instance: InstanceRef, indent: Rope = nil): Rope =
  result = &[
    indent,
    rope("create "),
    rope(instance.name),
    rope(": "),
    rope(instance.componentName),
    rope(" (\n"),
  ]
  for nodeName, bindingExpr in instance.bindings:
    result = &[
      result,
      indent,
      rope("  "),
      rope(nodeName),
      rope(" => "),
      rope(bindingExpr),
      rope(",\n"),
    ]
  result = result & indent & rope(");\n")

proc rope*(primitive: PrimitiveRef): Rope =
  result = &[
    rope("primitive "),
    rope(primitive.name),
    rope(" (\n"),
  ]
  for nodeName, width in primitive.portWidths:
    result = &[
      result,
      rope("  "),
      rope(nodeName),
      rope(": bits["),
      rope(width),
      rope("],\n"),
    ]
  result = &[
    result,
    rope(") {\n  device \""),
    rope(primitive.device),
    rope("\";\n  footprint \""),
    rope(primitive.footprint),
    rope("\";\n"),
  ]
  for pin, pinExpr in primitive.pinMapping:
    result = &[
      result,
      rope("  pin "),
      rope(pin),
      rope(" => "),
      rope(pinExpr),
      rope(";\n")
    ]
  result = result & rope("}\n")

proc rope*(composite: CompositeRef): Rope =
  result = &[
    rope("composite "),
    rope(composite.name),
    rope(" (\n"),
  ]
  for nodeName, width in composite.portWidths:
    result = &[
      result,
      rope("  "),
      rope(nodeName),
      rope(": bits["),
      rope(width),
      rope("],\n"),
    ]
  result = result & rope(") {\n")
  for nodeName, width in composite.nodeWidths:
    result = &[
      result,
      rope("  node "),
      rope(nodeName),
      rope(": bits["),
      rope(width),
      rope("];\n"),
    ]
  let indent = rope("  ")
  for instance in composite.instances:
    result = result & rope(instance, indent)
  result = result & rope("}\n")

proc rope*(unit: CompilationUnitRef): Rope =
  for nodeName, width in unit.nodeWidths:
    result = &[
      result,
      rope("node "),
      rope(nodeName),
      rope(": bits["),
      rope(width),
      rope("];\n"),
    ]
  for nodeName, aliasExpr in unit.aliases:
    result = &[
      result,
      rope("alias "),
      rope(nodeName),
      rope(" = "),
      rope(aliasExpr),
      rope(";\n"),
    ]
  for primitive in unit.primitives.values():
    result = result & rope(primitive)
  for composite in unit.composites.values():
    result = result & rope(composite)
  for instance in unit.instances:
    result = result & rope(instance)

proc `$`*(unit: CompilationUnitRef): string =
  $rope(unit)
