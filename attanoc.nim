import attano.parse
import attano.stringify
import attano.passes.check
import attano.passes.expandinstances
import attano.passes.dereference

let unit = parseStdin()

let messages = check(unit)
if messages.len() > 0:
  for message in messages:
    echo message
  quit(1)

expandInstances(unit)
assert len(check(unit)) == 0
dereference(unit)
assert len(check(unit)) == 0

echo $unit
