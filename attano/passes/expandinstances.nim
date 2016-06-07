import tables
import attano.types

proc substitute(e: PExpr, bindings: OrderedTable[NodeName, PExpr], renames: Table[NodeName, NodeName]): PExpr =
  case e.kind
  of exprNodeRef:
    result =
      if e.node in bindings:
        bindings[e.node]
      elif e.node in renames:
        PExpr(
          loc: e.loc,
          kind: exprNodeRef,
          node: renames[e.node],
        )
      else:
        e
  of exprLiteral:
    result = e
  of exprConcat:
    var newChildren = newSeq[PExpr](e.concatChildren.len())
    for i, child in e.concatChildren:
      newChildren[i] = child.substitute(bindings, renames)
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
      multiplyChild: e.multiplyChild.substitute(bindings, renames),
    )
  of exprSlice:
    result = PExpr(
      loc: e.loc,
      kind: exprSlice,
      sliceUpperBound: e.sliceUpperBound,
      sliceLowerBound: e.sliceLowerBound,
      sliceChild: e.sliceChild.substitute(bindings, renames),
    )

proc instantiate(unit: PCompilationUnit, loc: Loc, name: InstanceName, compositeName: CompositeName, bindings: OrderedTable[NodeName, PExpr]) =
  let compositeDef = unit.composites[compositeName]
  
  var renames = initTable[NodeName, NodeName]()
  for nodeDef in compositeDef.nodes.values():
    renames[nodeDef.name] = name & "." & nodeDef.name
  for aliasDef in compositeDef.aliases.values():
    renames[aliasDef.name] = name & "." & aliasDef.name
  
  # Nodes
  for nodeDef in compositeDef.nodes.values():
    let newNodeDef = PNodeDef(
      loc: nodeDef.loc,
      name: renames[nodeDef.name],
      width: nodeDef.width,
    )
    unit.nodes[newNodeDef.name] = newNodeDef
  
  # Aliases
  for aliasDef in compositeDef.aliases.values():
    let newAliasDef = PAliasDef(
      loc: aliasDef.loc,
      name: renames[aliasDef.name],
      value: aliasDef.value.substitute(bindings, renames),
    )
    unit.aliases[newAliasDef.name] = newAliasDef
  
  # Primitives
  for primitiveDef in compositeDef.primitives.values():
    var newPinBindings = initOrderedTable[PinNumber, PExpr]()
    for pin, exp in primitiveDef.pinBindings:
      newPinBindings[pin] = exp.substitute(bindings, renames)
    let newPrimitiveDef = PPrimitiveDef(
      loc: primitiveDef.loc,
      name: name & "." & primitiveDef.name,
      device: primitiveDef.device,
      footprint: primitiveDef.footprint,
      pinBindings: newPinBindings,
    )
    unit.primitives[newPrimitiveDef.name] = newPrimitiveDef
  
  # Instances
  for instanceDef in compositeDef.instances.values():
    let newInstanceName = name & "." & instanceDef.name
    var newInstanceBindings = initOrderedTable[NodeName, PExpr]()
    for name, exp in instanceDef.bindings:
      newInstanceBindings[name] = exp.substitute(bindings, renames)
    instantiate(unit, instanceDef.loc, newInstanceName, instanceDef.compositeName, newInstanceBindings)

proc expandInstances*(unit: PCompilationUnit) =
  for instance in unit.instances.values():
    instantiate(unit, instance.loc, instance.name, instance.compositeName, instance.bindings)
  
  unit.composites = initOrderedTable[CompositeName, PCompositeDef]()
  unit.instances = initOrderedTable[InstanceName, PInstanceDef]()
  
  # use these instead once we are compiling with Nim v0.14
  #unit.composites.clear()
  #unit.instances.clear()
