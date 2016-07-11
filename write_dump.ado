/* 
 * The write_dump program calls the mata function write_dump() to write data to
 * a (dump) file. The only required argument is the file name. If `anything' is
 * not specified, the default is to dump all numeric scalars, globals, matrices,
 * and variables in memory. With the replace option, the file will be
 * overwritten.
 */
program define write_dump
syntax [anything] using/ [, replace]

if "`anything'" == "" local dump_list "dump_all" 
else                  local dump_list "`anything'"

mata write_dump("`using'", "`dump_list'", "`replace'")
end

/*
 * Write dump_list to file fn
 * @param fn File name of the dump file
 * @param dump_list "dump_all", or list of scalar, global, matrix, and variable
 * @param replace_or_not Remove fn if replace_or_not == "replace", else ignored
 * @return None
 * @example write_dump_test.do
 */
mata:
void write_dump(fn, dump_list, |replace_or_not) {
	if (replace_or_not == "replace") {
		unlink(fn)
		printf("{res}File %s is removed.\n", fn)
		write_append = "Writing"
	}
	else write_append = "Appending"
	
	list_scalar = st_dir("global", "numscalar", "*")
	list_matrix = st_dir("global", "matrix", "*")
	list_var = st_varname(1..st_nvar())

	// ignore globals used by Stata, i.e. those beginning with S_*
	list_global = st_dir("global", "macro", "*")
	list_system = st_dir("global", "macro", "S_*")
	st_local("stata_global", invtokens(rowshape(list_global, 1)))
	st_local("stata_system", invtokens(rowshape(list_system, 1)))
	stata("local list_global : list stata_global - stata_system")
	list_global = tokens(st_local("list_global"))
	
	if (dump_list != "dump_all") {
		// first take the mata lists into stata;
		// then use the extended macro function, list.
		// see "help macrolists": A & B returns the intersection of A and B.
		st_local("stata_scalar", invtokens(rowshape(list_scalar, 1)))
		st_local("stata_global", invtokens(rowshape(list_global, 1)))
		st_local("stata_matrix", invtokens(rowshape(list_matrix, 1)))
		st_local("stata_var", invtokens(rowshape(list_var, 1)))
		stata("local list_scalar : list anything & stata_scalar")
		stata("local list_global : list anything & stata_global")
		stata("local list_matrix : list anything & stata_matrix")
		stata("local list_var : list anything & stata_var")
		// back to mata
		list_scalar = tokens(st_local("list_scalar"))
		list_global = tokens(st_local("list_global"))
		list_matrix = tokens(st_local("list_matrix"))
		list_var = tokens(st_local("list_var"))
	}
	
	printf("{res}\n%s data to %s:\n", write_append, fn)
	printf("{res}/* begin */\n")
	
	// writing scalars
	for (i = 1; i <= length(list_scalar); i++) {
		sname = list_scalar[i]
		s = st_numscalar(sname)
		values_str = strofreal(s)
		fh = fopen(fn, "a")
		fput(fh, sprintf("%s =\n%s", sname, values_str))
		fclose(fh)
		printf("%s =\n%s\n", sname, values_str)
	}
	// writing globals
	for (i = 1; i <= length(list_global); i++) {
		gmname = list_global[i]
		gm = st_global(gmname)
		if (strtoreal(gm) != .) {
			values_str = gm
			fh = fopen(fn, "a")
			fput(fh, sprintf("%s =\n%s", gmname, values_str))
			fclose(fh)
			printf("%s =\n%s\n", gmname, values_str)
		}
	}
	// writing matrices
	for (i = 1; i <= length(list_matrix); i++) {
		mtxname = list_matrix[i]
		mtx = st_matrix(mtxname)
		values_str = invtokens(strofreal(transposeonly(vec(mtx))))
		values_str_comma = subinstr(values_str, " ", ", ")
		fh = fopen(fn, "a")
		fput(fh, sprintf("%s =\nstructure(c(%s), .Dim = c(%g, %g))", ///
		                 mtxname, values_str_comma, rows(mtx), cols(mtx)))
		fclose(fh)
		if (strlen(values_str_comma) > 80) { // truncate if too long
			values_to_print = substr(values_str_comma, 1, 80) + ///
				" ...(truncated)"
		}
		else values_to_print = values_str_comma
		printf("%s =\nstructure(c(%s), .Dim = c(%g, %g))\n", ///
		       mtxname, values_to_print, rows(mtx), cols(mtx))
	}
	// writing stata variables
	notnumvar = ""
	for (i = 1; i <= length(list_var); i++) {
		vname = list_var[i]
		v = st_data(., vname)
		if (st_isnumvar(vname)) {
			values_str = invtokens(strofreal(transposeonly(v)))
			values_str_NaN = subinstr(values_str, " . ", " NaN ")
			values_str_comma = subinstr(values_str_NaN, " ", ", ")
			fh = fopen(fn, "a")
			fput(fh, sprintf("%s =\nc(%s)", vname, values_str_comma))
			fclose(fh)
			if (strlen(values_str_comma) >= 80) { // truncate if too long
				values_to_print = substr(values_str_comma, 1, 80) + ///
					" ...(truncated)"
				}
			else values_to_print = values_str_comma
			printf("%s =\nc(%s)\n", vname, values_to_print)
		}
		else notnumvar = notnumvar + vname
	}
	printf("{res}/* end */\n")
	
	if (strlen(notnumvar) > 0) {
		printf("\n{error}Warning message:\n" +
		       "One or more non-numeric variables " +
			   "are not written to %s:\n%s\n", fn, notnumvar)
	}
}
end
