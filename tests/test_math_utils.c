#include <stdio.h>
#include <stdlib.h>
#include "../src/math_utils.h"

#define ASSERT(cond, msg) \
    if (!(cond)) { fprintf(stderr, "FAIL: %s\n", msg); exit(1); } \
    else { printf("PASS: %s\n", msg); }

int main(void) {
    ASSERT(add(2, 3) == 5,  "add(2, 3) == 5");
    ASSERT(add(0, 0) == 0,  "add(0, 0) == 0");
    ASSERT(add(-1, 1) == 0, "add(-1, 1) == 0");
    printf("All tests passed.\n");
    return 0;
}
