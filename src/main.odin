package main

import "lib:lexer"
import "lib:parser"
import "core:fmt"

import "lib:dotprinter"

print :: fmt.println;
printf :: fmt.printf;

/*
	NEXT STEPS:
		error sync problem
*/


main :: proc ()
{
	tokens := lexer.run ("../main.meta");
	// for t in tokens do print(t);

	stmts := parser.run( tokens );

	print("digraph Main {\n");
	for s in stmts
	{
		dotprinter.dot_stmt_printer(s);
	}
	print("\n}\n");

	
	// ast_to_c(expr);

	// x:= 1 + 2 / 3 / - - 4 /;



	// fmt.println(child_a.V);

	// tokens := lexer_run( "main.meta" );
	// parser_run( tokens );
}