package main

import "meta:lexer"
import "meta:parser"
import "core:fmt"

print :: fmt.println;
printf :: fmt.printf;

ast_printer :: proc ( stmt: ^parser.Stmt, l: int = 0 )
{
	#partial switch stmt.type
	{
		case .Var_Decl:
			v := cast(^parser.Var_Decl) stmt;
			printf("Var Decl: %v \n", v.var.text);
			ast_expr_printer( v.init, l+1 );

		case .Error:
			v := cast(^parser.Error_Stmt) stmt;
			print(v.error);
	}
}

ast_expr_printer :: proc ( expr: ^parser.Expr, l: int = 0 )
{
	for _ in 0 ..< l do printf("    ");

	switch expr.type
	{
		case .Binary:
			v := cast( ^parser.Binary ) expr;
			printf("Binary: %v\n", v.op.text);
			ast_expr_printer( v.left, l + 1 );
			ast_expr_printer( v.right, l + 1 );
		case .Unary:
			v := cast( ^parser.Unary ) expr;
			printf("Unary: %v\n", v.op.text );
			ast_expr_printer( v.right, l + 1 );
		case .Literal:
			v := cast( ^parser.Literal ) expr;
			printf("Literal: %v ", v.value.text );
			printf("\n");
		case .Var:
			v := cast( ^parser.Var ) expr;
			printf("Var: %v ", v.var.text );
			printf("\n");
		case .Grouping:
			v := cast( ^parser.Grouping ) expr;
			printf("Grouping:\n" );
			ast_expr_printer(v.group, l + 1);

		case .Error:
			v := cast( ^parser.Error_Expr ) expr;
			printf("%v ", v.error);
			printf("at: %v\n", v.token.text);

		case:
			print("not implemented: ");
			print( expr );
	}
	
}

ast_to_c :: proc ( expr: ^parser.Expr )
{

	#partial switch expr.type
	{
		case .Binary:
			v := cast( ^parser.Binary ) expr;
			ast_to_c( v.left );
			printf("%v", v.op.text);
			ast_to_c( v.right );
		case .Unary:
			v := cast( ^parser.Unary ) expr;
			printf("%v", v.op.text );
			ast_to_c( v.right );
		case .Literal:
			v := cast( ^parser.Literal ) expr;
			printf("%v", v.value.text );
			
		case .Grouping:
			v := cast( ^parser.Grouping ) expr;
			printf("(");
			ast_to_c(v.group);
			printf(")");

		case .Error:
			v := cast( ^parser.Error_Expr ) expr;
			printf("%v ", v.error);
			printf("at: %v\n", v.token.text);

		case:
			print("not implemented: ");
			print( expr );
	}
}



/*
	ERROR:
		expr error return to statements that generate an error too. 
		so the error showing is WRONG. 
		one solution is to copy the error text msg if an expression is an error type.

	NEXT STEPS:
		assignment
		scopes = {} blocks
*/

main :: proc ()
{
	tokens := lexer.run ("main.meta");
	for t in tokens do print(t);

	stmts := parser.run( tokens );

	for s in stmts
	{
		print("Statement: ");
		ast_printer(s);	
	}

	
	// ast_to_c(expr);

	// x:= 1 + 2 / 3 / - - 4 /;



	// fmt.println(child_a.V);

	// tokens := lexer_run( "main.meta" );
	// parser_run( tokens );
}