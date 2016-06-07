from strutils import `%`
import tables
import attano.types

type
  NodeInfo = tuple
    loc: Loc
    width: int
  
  InstanceInfo = tuple
    loc: Loc
  
  Checker = object
    unit: PCompilationUnit
    messages: seq[string]
    globalNodes: Table[NodeName, NodeInfo]
    globalInstances: Table[InstanceName, InstanceInfo]
  
  PChecker = ref Checker
  
  CompositeChecker = object
    parent: PChecker
    compositeDef: PCompositeDef
    localNodes: Table[NodeName, NodeInfo]
    localInstances: Table[InstanceName, InstanceInfo]
  
  PCompositeChecker = ref CompositeChecker

proc error(c: PChecker, loc: Loc, msg: string) {.noSideEffect.} =
  c.messages.add("$1: $2" % [$loc, msg])

proc error(c: PCompositeChecker, loc: Loc, msg: string) {.noSideEffect.} =
  c.parent.error(loc, msg)

proc walk(c: PChecker, e: PExpr, cc: PCompositeChecker = nil, disconnectedAllowed: bool = false): int =
  case e.kind
  of exprNodeRef:
    if cc != nil and e.node in cc.localNodes:
      result = cc.localNodes[e.node].width
    elif e.node in c.globalNodes:
      result = c.globalNodes[e.node].width
    else:
      c.error(e.loc, "undefined reference to node '$1'" % [$e.node])
      result = 1 # fallback

  of exprLiteral:
    # 64 will probably work, but don't want to take the risk
    if e.literalWidth > 63:
      c.error(e.loc, "literal widths greater than 63 are not supported")
    let max = (1 shl e.literalWidth) - 1
    if e.literalValue > max:
      c.error(e.loc, "literal value is greater than the largest representable $1-bit value ($2)" % [$e.literalWidth, $max])
    result = e.literalWidth

  of exprDisconnected:
    if not disconnectedAllowed:
      c.error(e.loc, "'disconnected' is disallowed in this context")
    result = 1

  of exprConcat:
    for child in e.concatChildren:
      let childWidth = c.walk(child, cc, disconnectedAllowed)
      result += childWidth

  of exprMultiply:
    let childWidth = c.walk(e.multiplyChild, cc, disconnectedAllowed)
    result = e.multiplyCount * childWidth

  of exprSlice:
    let childWidth = c.walk(e.sliceChild, cc, disconnectedAllowed)
    if e.sliceUpperBound >= childWidth:
      c.error(e.loc, "upper bound '$1' out of range (must be in range 0..$2 inclusive)" % [$e.sliceUpperBound, $(childWidth-1)])
    if e.sliceLowerBound >= childWidth:
      c.error(e.loc, "lower bound '$1' out of range (must be in range 0..$2 inclusive)" % [$e.sliceLowerBound, $(childWidth-1)])
    if e.sliceUpperBound < e.sliceLowerBound:
      c.error(e.loc, "upper bound '$1' must be greater than or equal to lower bound '$2'" % [$e.sliceUpperBound, $e.sliceLowerBound])
    result = e.sliceUpperBound - e.sliceLowerBound + 1

  if c.messages.len() == 0:
    assert result > 0

proc checkPrimitive(c: PChecker, primitiveDef: PPrimitiveDef, cc: PCompositeChecker = nil) =
  let numPins = primitiveDef.pinBindings.len()
  let validPins = PinNumber(1) .. PinNumber(numPins)
  for pin, exp in primitiveDef.pinBindings:
    if pin notin validPins:
      c.error(primitiveDef.loc, "invalid pin number '$1' (expected to be between 1 and $2 inclusive)" % [$pin, $numPins])
    let width = c.walk(exp, cc, disconnectedAllowed = true)
    if width != 1:
      c.error(primitiveDef.loc, "width mismatch at pin '$1': expected a width of 1, but the bound expression has a width of $2" % [$pin, $width])

proc checkInstance(c: PChecker, instanceDef: PInstanceDef, cc: PCompositeChecker = nil) =
  if instanceDef.compositeName notin c.unit.composites:
    c.error(instanceDef.loc, "reference to undefined composite '$1'" % [instanceDef.compositeName])
  else:
    let compositeDef = c.unit.composites[instanceDef.compositeName]
    for portName, exp in instanceDef.bindings:
      if portName notin compositeDef.portWidths:
        c.error(instanceDef.loc, "undefined reference to composite port '$1'" % [portName])
      else:
        let expectedWidth = compositeDef.portWidths[portName]
        let actualWidth = c.walk(exp, cc, disconnectedAllowed = true)
        if actualWidth != expectedWidth:
          c.error(instanceDef.loc, "width mismatch at port '$1': expected a width of $2, but the bound expression has width $3" % [portName, $expectedWidth, $actualWidth])
    if len(instanceDef.bindings) < len(compositeDef.portWidths):
      c.error(instanceDef.loc, "at least one composite ports is left unbound")

proc checkNodes(c: PChecker) =
  for name, nodeDef in c.unit.nodes:
    assert(name == nodeDef.name)
    if name in c.globalNodes:
      c.error(nodeDef.loc, "redefinition of node '$1' (previous definition at $2)" % [name, $c.globalNodes[name].loc])
    else:
      c.globalNodes[name] = (loc: nodeDef.loc, width: nodeDef.width)

proc checkNodes(cc: PCompositeChecker) =
  for name, nodeDef in cc.compositeDef.nodes:
    assert(name == nodeDef.name)
    if name in cc.localNodes:
      cc.error(nodeDef.loc, "redefinition of node '$1' (previous definition at $2)" % [name, $cc.localNodes[name].loc])
    elif name in cc.parent.globalNodes:
      cc.error(nodeDef.loc, "redefinition of node '$1' (previous definition at $2)" % [name, $cc.parent.globalNodes[name].loc])
    else:
      cc.localNodes[name] = (loc: nodeDef.loc, width: nodeDef.width)

proc checkAliases(c: PChecker) =
  for name, aliasDef in c.unit.aliases:
    assert(name == aliasDef.name)
    if name in c.globalNodes:
      c.error(aliasDef.loc, "redefinition of node '$1' (previous definition at $2)" % [name, $c.globalNodes[name].loc])
    else:
      let width = c.walk(aliasDef.value)
      c.globalNodes[name] = (loc: aliasDef.loc, width: width)

proc checkAliases(cc: PCompositeChecker) =
  for name, aliasDef in cc.compositeDef.aliases:
    assert(name == aliasDef.name)
    if name in cc.localNodes:
      cc.error(aliasDef.loc, "redefinition of node '$1' (previous definition at $2)" % [name, $cc.localNodes[name].loc])
    elif name in cc.parent.globalNodes:
      cc.error(aliasDef.loc, "redefinition of node '$1' (previous definition at $2)" % [name, $cc.parent.globalNodes[name].loc])
    else:
      let width = cc.parent.walk(aliasDef.value, cc)
      cc.localNodes[name] = (loc: aliasDef.loc, width: width)

proc checkPrimitives(c: PChecker) =
  for name, primitiveDef in c.unit.primitives:
    assert(name == primitiveDef.name)
    if name in c.globalInstances:
      c.error(primitiveDef.loc, "redefinition of primitive or instance '$1' (previous definition at $2)" % [name, $c.globalInstances[name].loc])
    else:
      c.globalInstances[name] = (loc: primitiveDef.loc)
      c.checkPrimitive(primitiveDef)

proc checkPrimitives(cc: PCompositeChecker) =
  for name, primitiveDef in cc.compositeDef.primitives:
    assert(name == primitiveDef.name)
    if name in cc.localInstances:
      cc.error(primitiveDef.loc, "redefinition of primitive or instance '$1' (previous definition at $2)" % [name, $cc.localInstances[name].loc])
    elif name in cc.parent.globalInstances:
      cc.error(primitiveDef.loc, "redefinition of primitive or instance '$1' (previous definition at $2)" % [name, $cc.parent.globalInstances[name].loc])
    else:
      cc.localInstances[name] = (loc: primitiveDef.loc)
      cc.parent.checkPrimitive(primitiveDef, cc)

proc checkInstances(c: PChecker) =
  for name, instanceDef in c.unit.instances:
    assert(name == instanceDef.name)
    if name in c.globalInstances:
      c.error(instanceDef.loc, "redefinition of primitive or instance '$1' (previous definition at $2)" % [name, $c.globalInstances[name].loc])
    else:
      c.globalInstances[name] = (loc: instanceDef.loc)
      c.checkInstance(instanceDef)

proc checkInstances(cc: PCompositeChecker) =
  for name, instanceDef in cc.compositeDef.instances:
    assert(name == instanceDef.name)
    if name in cc.localInstances:
      cc.error(instanceDef.loc, "redefinition of primitive or instance '$1' (previous definition at $2)" % [name, $cc.localInstances[name].loc])
    elif name in cc.parent.globalInstances:
      cc.error(instanceDef.loc, "redefinition of primitive or instance '$1' (previous definition at $2)" % [name, $cc.parent.globalInstances[name].loc])
    else:
      cc.localInstances[name] = (loc: instanceDef.loc)
      if instanceDef.compositeName == cc.compositeDef.name:
        cc.error(instanceDef.loc, "recursive instantiation of composite '$1' is disallowed" % [instanceDef.compositeName])
      else:
        cc.parent.checkInstance(instanceDef, cc)

proc checkComposites(c: PChecker) =
  for name, compositeDef in c.unit.composites:
    assert(name == compositeDef.name)
    let cc = PCompositeChecker(
      parent: c,
      compositeDef: compositeDef,
      localNodes: initTable[NodeName, NodeInfo](),
      localInstances: initTable[InstanceName, InstanceInfo](),
    )
    for portName, width in compositeDef.portWidths:
      cc.localNodes[portName] = (loc: compositeDef.loc, width: width)
    cc.checkNodes()
    cc.checkAliases()
    cc.checkPrimitives()
    cc.checkInstances()

proc check*(unit: PCompilationUnit): seq[string] =
  let c = PChecker(
    unit: unit,
    messages: @[],
    globalNodes: initTable[NodeName, NodeInfo](),
    globalInstances: initTable[InstanceName, InstanceInfo](),
  )
  c.checkComposites()
  c.checkNodes()
  c.checkAliases()
  c.checkPrimitives()
  c.checkInstances()
  result = c.messages
