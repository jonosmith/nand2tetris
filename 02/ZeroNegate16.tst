load ZeroNegate16.hdl,
output-file ZeroNegate16.out,
compare-to ZeroNegate16.cmp,
output-list in%B1.16.1 zero%B1.1.1 negate%B1.1.1 out%B1.16.1;

set in %B0000000000000001;

set zero 0,
set negate 0,
eval,
output;

set zero 0,
set negate 0,
eval,
output;

set zero 0,
set negate 0,
eval,
output;

set zero 0,
set negate 0,
eval,
output;
