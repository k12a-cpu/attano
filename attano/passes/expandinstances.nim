from strutils import `%`
import tables
import attano.types

proc substitute(e: ExprRef, bindings: OrderedTable[NodeName, ExprRef], renames: Table[NodeName, NodeName]): ExprRef =
  case e.kind
  of exprNodeRef:
    result =
      if e.node in bindings:
        bindings[e.node]
      elif e.node in renames:
        ExprRef(
          loc: e.loc,
          kind: exprNodeRef,
          node: renames[e.node],
        )
      else:
        e
  of exprLiteral:
    result = e
  of exprConcat:
    var newChildren = newSeq[ExprRef](e.concatChildren.len())
    for i, child in e.concatChildren:
      newChildren[i] = child.substitute(bindings, renames)
    result = ExprRef(
      loc: e.loc,
      kind: exprConcat,
      concatChildren: newChildren,
    )
  of exprMultiply:
    result = ExprRef(
      loc: e.loc,
      kind: exprMultiply,
      multiplyCount: e.multiplyCount,
      multiplyChild: e.multiplyChild.substitute(bindings, renames),
    )
  of exprSlice:
    result = ExprRef(
      loc: e.loc,
      kind: exprSlice,
      sliceUpperBound: e.sliceUpperBound,
      sliceLowerBound: e.sliceLowerBound,
      sliceChild: e.sliceChild.substitute(bindings, renames),
    )

proc instantiate(unit: CompilationUnitRef, loc: Loc, name: string, componentName: string, bindings: OrderedTable[NodeName, ExprRef]) =
  if componentName in unit.primitives:
    unit.instances.add(InstanceRef(
      loc: loc,
      name: name,
      componentName: componentName,
      bindings: bindings,
    ))
  elif componentName in unit.composites:
    let composite = unit.composites[componentName]
    var renames = initTable[NodeName, NodeName]()
    for subNode, subNodeWidth in composite.nodeWidths:
      let newName = "$1.$2" % [name, subNode]
      renames[subNode] = newName
      unit.nodeWidths[newName] = subNodeWidth
    for subInstance in composite.instances:
      var newBindings = initOrderedTable[NodeName, ExprRef]()
      for name, value in subInstance.bindings:
        newBindings[name] = value.substitute(bindings, renames)
      let newName = "$1.$2" % [name, subInstance.name]
      instantiate(unit, loc, newName, subInstance.componentName, newBindings)

proc expandInstances*(unit: CompilationUnitRef) =
  let instances = unit.instances
  unit.instances = @[]
  for instance in instances:
    instantiate(unit, instance.loc, instance.name, instance.componentName, instance.bindings)
  unit.composites = initOrderedTable[ComponentName, ref Composite]() # empty it, as they are no longer necessary
