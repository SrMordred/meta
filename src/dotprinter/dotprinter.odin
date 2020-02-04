package meta


import "core:fmt"
import "core:mem"
import "core:strings"
import "lib:parser"
import "lib:lexer"

print :: fmt.println;
printf :: fmt.printf;


dot_id := 1;

beauty_error :: proc ( token: ^lexer.Token, error: string ) -> string
{
	type := token.type;
	text := token.text;
	line := token.line;
	col  := token.col;

	line_start := mem.ptr_offset(strings.ptr_from_string(text), -(int(col)-1-len(text)) );
	// printf("line start = %c\n", line_start^);
	line_end := line_start;
	len := 0;
	for
	{
		if line_end^ == '\n' || line_end^ == 0 do break;
		line_end = mem.ptr_offset(line_end, 1);
	}
	line_text := strings.string_from_ptr( line_start, mem.ptr_sub(line_end, line_start) );

	err := `main.meta
%v

%v|  %v
`;

	return fmt.tprintf( err, error, line, line_text );
}

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
			id := dot( parent, 
				"Var-Decl: %v : %v", 
				v.var_id.text, v.var_type.type == .AUTO ? "Auto": v.var_type.text
				);
			dot_expr_printer( v.init, id );


		case .Var_Assign:
			v := cast(^parser.Var_Assign) stmt;
			id := dot( parent ,"Var-Assign: %v", v.var.text);
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

		case .While:
			v := cast(^parser.While) stmt;
			id := dot(parent, "While");
			id2 := dot(id, "While-Cond" );
			dot_expr_printer( v.cond, id2 );
			id3 := dot(id,"Loop");
			dot_stmt_printer( v.loop, id3 );

		case .Error:
			v := cast(^parser.Error_Stmt) stmt;
			dot(parent, beauty_error(v.token, v.error) );
	}
}

dot_expr_printer :: proc ( expr: ^parser.Expr, parent:= 0 )
{
	switch expr.type
	{
		case .Binary:
			v := cast( ^parser.Binary ) expr;
			id:= dot(parent,"Binary: %v", v.op.text);
			dot_expr_printer( v.left, id );
			dot_expr_printer( v.right, id );

		case .Logical:
			v := cast( ^parser.Logical ) expr;
			id:= dot(parent,"Logical: %v", v.op.text);
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
			dot(parent, beauty_error(v.token, v.error) );

			// dot(parent,"Error: %v ", v.error );
			// printf("at: %v\n", v.token.text);
		case .Noop:
		case:
			print("not implemented: ");
			print( expr );
	}
	
}