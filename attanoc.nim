import docopt

import attano.parse
import attano.stringify
import attano.passes.check
import attano.passes.expandinstances
import attano.passes.dereference
import attano.passes.flattennodes
from attano.types import newCompilationUnit

const doc = """
attanoc - Attano compiler.

Usage:
  attanoc [options] <infile>...

Options:
  -h, --help                          Print this help text.
"""

let args = docopt(doc)

let unit = newCompilationUnit()
for filename in args["<infile>"]:
  if filename == "-":
    parseStdin(unit)
  else:
    parseFile(unit, filename)

let messages = check(unit)
if messages.len() > 0:
  for message in messages:
    echo message
  quit(1)

expandInstances(unit)
assert len(check(unit)) == 0
dereference(unit)
assert len(check(unit)) == 0
flattenNodes(unit)
assert len(check(unit)) == 0

echo $unit
