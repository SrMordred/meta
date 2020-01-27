package main

import "meta:lexer"
import "meta:parser"
import "core:fmt"

print :: fmt.println;
printf :: fmt.printf;

ast_stmt_printer :: proc ( stmt: ^parser.Stmt, l: int = 0 )
{
	for _ in 0 ..< l do printf("  ");

	#partial switch stmt.type
	{
		case .Var_Decl:
			v := cast(^parser.Var_Decl) stmt;
			printf("Decl: %v \n", v.var.text);
			ast_expr_printer( v.init, l+1 );

		case .Var_Assign:
			v := cast(^parser.Var_Assign) stmt;
			printf("Assign: %v \n", v.var.text);
			ast_expr_printer( v.init, l+1 );

		case .Expr_Stmt:
			v := cast(^parser.Expr_Stmt) stmt;
			printf("Expr:\n");
			ast_expr_printer( v.expr, l+1 );

		case .Block:
			v := cast(^parser.Block) stmt;
			printf("Block:\n");
			for stmt in v.stmts do ast_stmt_printer(stmt, l+1);

		case .If:
			v := cast(^parser.If) stmt;
			printf("If:\n");
			printf("  If-Cond:\n");
			ast_expr_printer( v.cond, l+2 );
			printf("  Then:\n");
			ast_stmt_printer( v.then, l+2 );
			if v._else != nil
			{
				printf("  Else:\n");
				ast_stmt_printer( v._else, l+2 );	
			}
		case .Error:
			v := cast(^parser.Error_Stmt) stmt;
			print(v.error);
	}
}

ast_expr_printer :: proc ( expr: ^parser.Expr, l: int = 0 )
{
	for _ in 0 ..< l do printf("  ");

	switch expr.type
	{
		case .Binary:
			v := cast( ^parser.Binary ) expr;
			printf("Bin-Op: %v\n", v.op.text);
			ast_expr_printer( v.left, l + 1 );
			ast_expr_printer( v.right, l + 1 );
		case .Unary:
			v := cast( ^parser.Unary ) expr;
			printf("Unary: %v\n", v.op.text );
			ast_expr_printer( v.right, l + 1 );
		case .Literal:
			v := cast( ^parser.Literal ) expr;
			printf("Lit: %v ", v.value.text );
			printf("\n");
		case .Var:
			v := cast( ^parser.Var ) expr;
			printf("Var: %v ", v.var.text );
			printf("\n");
		case .Grouping:
			v := cast( ^parser.Grouping ) expr;
			printf("Group:\n" );
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

dot_id := 1;

dot :: proc ( parent:int, name: string, args:..any ) -> int
{
	name := fmt.tprintf(name, ..args);
	printf("%v [label=\"%v\"];\n", dot_id, name);
	if parent != 0
	{
		printf("%v -> %v;\n", parent, dot_id );
	}
	defer dot_id += 1;
	return dot_id;
}

dot_stmt_printer :: proc ( stmt: ^parser.Stmt, parent: int = 0 )
{
	#partial switch stmt.type
	{
		case .Var_Decl:
			v := cast(^parser.Var_Decl) stmt;
			id := dot( parent, "Decl: %v", v.var.text );
			dot_expr_printer( v.init, id );

		case .Var_Assign:
			v := cast(^parser.Var_Assign) stmt;
			id := dot( parent ,"Assign: %v", v.var.text);
			dot_expr_printer( v.init, id );

		case .Expr_Stmt:
			v := cast(^parser.Expr_Stmt) stmt;
			id := dot(parent, "Expr");
			dot_expr_printer( v.expr, id );

		case .Block:
			v := cast(^parser.Block) stmt;
			id := dot(parent, "Block");
			for stmt in v.stmts do dot_stmt_printer(stmt, id);

		case .If:
			v := cast(^parser.If) stmt;
			id := dot(parent, "If");
			id2 := dot(id, "If-Cond" );
			dot_expr_printer( v.cond, id2 );
			id3 := dot(id,"Then");
			dot_stmt_printer( v.then, id3 );
			if v._else != nil
			{
				id4:= dot(id, "Else");
				dot_stmt_printer( v._else, id4 );	
			}
		case .Error:
			v := cast(^parser.Error_Stmt) stmt;
			dot(parent, "Error: %v", v.error );
	}
}

dot_expr_printer :: proc ( expr: ^parser.Expr, parent:= 0 )
{
	switch expr.type
	{
		case .Binary:
			v := cast( ^parser.Binary ) expr;
			id:= dot(parent,"Bin-Op: %v", v.op.text);
			dot_expr_printer( v.left, id );
			dot_expr_printer( v.right, id );
		case .Unary:
			v := cast( ^parser.Unary ) expr;
			id := dot(parent, "Unary: %v", v.op.text );
			dot_expr_printer( v.right, id );
		case .Literal:
			v := cast( ^parser.Literal ) expr;
			id := dot(parent,"Lit: %v", v.value.text );
		case .Var:
			v := cast( ^parser.Var ) expr;
			id:= dot(parent, "Var: %v", v.var.text );
		case .Grouping:
			v := cast( ^parser.Grouping ) expr;
			id:= dot(parent, "Group:" );
			dot_expr_printer(v.group, id );

		case .Error:
			v := cast( ^parser.Error_Expr ) expr;
			dot(parent,"%v ", v.error );
			// printf("at: %v\n", v.token.text);
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
		if statements
*/

main :: proc ()
{
	tokens := lexer.run ("main.meta");
	// for t in tokens do print(t);

	stmts := parser.run( tokens );

	print("digraph Main {\n");
	for s in stmts
	{
		dot_stmt_printer(s);
	}
	print("\n}\n");

	
	// ast_to_c(expr);

	// x:= 1 + 2 / 3 / - - 4 /;



	// fmt.println(child_a.V);

	// tokens := lexer_run( "main.meta" );
	// parser_run( tokens );
}