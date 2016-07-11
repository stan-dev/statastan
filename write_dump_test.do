/*
 *  Example 1
 *  - If `anything' is not specified, the default is to dump all numeric
 *    scalars, globals, matrices, and variables in memory.
 *  - For variables, "." is converted to "NaN".
 *  - Non-numeric variable triggers a warning; anything else non-numeric is
 *    silently ignored.
 *  - With the replace option, the file test_dump.data.R will be overwritten.
 */
sysuse auto
write_dump using test_dump.data.R, replace

/*
 *  Example 2
 *  - If `anything' is specified, only those are written to the file.
 *  - Anything that is not a variable, scalar, global or matrix is silently
 *    ignored.
 */
sysuse auto
write_dump price mpg headroom this_doesnt_exist using test_dump.data.R, replace

/*
 *  Example 3
 *  - Same as example 2, but without the replace option. Hence, price, mpg,
 *    headroom will be appended to the file test_dump.data.R.
 */
sysuse auto
write_dump price mpg headroom this_doesnt_exist using test_dump.data.R

/*
 *  Example 4
 *  - Same as example 1, but matrices A, B and the scalar constant are also
 *    written to the file.
 */
capture matrix drop A B
capture scalar drop constant
sysuse auto

matrix A = (1, 2\ 3, 4)
matrix B = (5, 6, 7\ 8, 9, 10)
scalar constant = 123

write_dump using test_dump.data.R, replace

/*
 *  Example 5
 *  - Same as example 1, but matrices A, B, the scalar constant, and the globals
 *    N and M are also written to the file.
 */
capture matrix drop A B
capture scalar drop constant
capture macro drop N M
sysuse auto

matrix A = (1, 2\ 3, 4)
matrix B = (5, 6, 7\ 8, 9, 10)
scalar constant = 123
global N = 101
global M = 202

write_dump using test_dump.data.R, replace
