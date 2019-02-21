#include "foo.h"
#include <iostream>
using namespace std;
using namespace ABQ;

int main(int argc, char *argv[]) {
  Math m("000001.SH");
  cout << m.getM().data() << endl;
  cout << m.squared(44) << endl;
  return 0;
}
