import attano.parse
import attano.stringify
#import attano.passes.expandinstances

let unit = parseStdin()

#expandInstances(unit)

echo $unit
