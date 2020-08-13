/**

Low-end bare-metal embedded control library.

*/
module uctl;

public import uctl.num;
public import uctl.fix;
public import uctl.unit;
public import uctl.trig;
public import uctl.lt;
public import uctl.util;
public import uctl.test;

version(unittest) {
  import uctl.test: unittests;

  mixin unittests;
}
