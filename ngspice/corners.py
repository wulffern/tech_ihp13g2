#!/usr/bin/env python3
#
import yaml

with open("../cicsim/cicsim.yaml") as fi:
    obj = yaml.safe_load(fi)


template = """

.lib {name}
{spice}
.endl

"""

corners = obj["corner"]
with open("corners.spi","w") as fo:
    for c in corners:
        fo.write(template.replace("{name}",c).replace("{spice}",corners[c]))
