import docopt

import attano.parse
import attano.stringify
import attano.svgen
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
  -O OP, --operation OP               Operation to perform; see the Operations
                                      section for a list of possibilities.
                                      [default: attano]

Operations:
  attano                              Print the AST in Attano format after
                                      transformations have been applied.
  sv                                  Generate a SystemVerilog module.
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

case $args["--operation"]
of "attano":
  echo $unit
of "sv":
  echo unit.toSV()
else:
  echo "error: invalid operation."
  echo "See --help for valid choices."
  quit(1)
