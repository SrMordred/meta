package parser;

Stmt_Type :: enum
{
	Var_Decl,
	Var_Assign,
	Expr_Stmt,
	Block,
	If,
	While,
	Error
}

Expr_Type :: enum
{
	Binary,
	Logical,
	Unary,
	Grouping,
	Literal,
	Var,
	Error,
	Noop
}

Stmt :: struct
{
	type: Stmt_Type
}

If :: struct
{
	using node: Stmt,
	cond: ^Expr,
	then: ^Stmt,
	_else: ^Stmt
}

While :: struct
{
	using node: Stmt,
	cond: ^Expr,
	loop: ^Stmt,
}

Block :: struct
{
	using node: Stmt,
	stmts: []^Stmt	
}

Expr_Stmt :: struct
{
	using node: Stmt,
	expr: ^Expr
}

Var_Decl :: struct
{
	using node: Stmt,
	var_id: ^Token,
	var_type: ^Token,
	init: ^Expr
}

Var_Assign :: struct
{
	using node: Stmt,
	var: ^Token,
	init: ^Expr	
}



Package :: struct
{
	stmts :[]^Statement
}

Statement :: struct
{
	expr: ^Expr
}

Expr :: struct
{
	type: Expr_Type
}

Binary :: struct
{
	using expr: Expr,
	left, right: ^Expr,
	op: ^Token
}

Logical :: struct
{
	using expr: Expr,
	left, right: ^Expr,
	op: ^Token
}

Unary :: struct
{
	using expr: Expr,
	right: ^Expr,
	op: ^Token
}

Grouping :: struct
{
	using expr: Expr,
	group: ^Expr
}

Literal :: struct
{
	using expr: Expr,
	value: ^Token
}

Var :: struct
{
	using expr: Expr,
	var: ^Token
}

Noop :: struct
{
	using expr: Expr,
}

Error_Expr :: struct
{
	using expr: Expr,
	error: string,
	token: ^Token
}

Error_Stmt :: struct
{
	using stmt: Stmt,
	error: string,
	token: ^Token
}

make_binary :: proc ( left, right: ^Expr, op: ^Token ) -> ^Expr
{
	expr := new( Binary );
	expr.type  = .Binary;
	expr.left  = left;
	expr.right = right;
	expr.op    = op;
	return expr;
}

make_unary :: proc ( right: ^Expr, op: ^Token ) -> ^Expr
{
	expr := new( Unary );
	expr.type  = .Unary;
	expr.right = right;
	expr.op    = op;
	return expr;
}

make_grouping :: proc ( group: ^Expr ) -> ^Expr
{
	expr := new( Grouping );
	expr.type  = .Grouping;
	expr.group = group;
	return expr;
}

make_literal :: proc ( value: ^Token ) -> ^Expr
{
	expr := new( Literal );
	expr.type = .Literal;
	expr.value = value;
	return expr;
}

make_var :: proc ( var: ^Token ) -> ^Expr
{
	expr := new( Var );
	expr.type = .Var;
	expr.var = var;
	return expr;
}

make_var_decl :: proc ( var_id: ^Token, var_type:^Token, init: ^Expr ) -> ^Stmt
{
	stmt :        = new( Var_Decl );
	stmt.type     = .Var_Decl;
	stmt.var_id   = var_id;
	stmt.var_type = var_type;
	stmt.init     = init;
	return stmt;
}

make_var_assign :: proc ( var: ^Token, init: ^Expr ) -> ^Stmt
{
	stmt := new( Var_Assign );
	stmt.type = .Var_Assign;
	stmt.var  = var;
	stmt.init = init;
	return stmt;
}

make_expr_stmt :: proc ( expr: ^Expr ) -> ^Stmt
{
	stmt := new( Expr_Stmt );
	stmt.type = .Expr_Stmt;
	stmt.expr  = expr;
	return stmt;
}

make_block :: proc ( stmts: []^Stmt ) -> ^Stmt
{
	stmt := new( Block );
	stmt.type = .Block;
	stmt.stmts  = stmts;
	return stmt;
}

make_if :: proc ( cond: ^Expr, then: ^Stmt, _else: ^Stmt ) -> ^Stmt
{
	stmt :       = new( If );
	stmt.type    = .If;
	stmt.cond    = cond;
	stmt.then    = then;
	stmt._else   = _else;
	return stmt;
}

make_while :: proc ( cond: ^Expr, loop: ^Stmt ) -> ^Stmt
{
	stmt := new( While );
	stmt.type    = .While;
	stmt.cond    = cond;
	stmt.loop    = loop;
	return stmt;
}

make_logical :: proc ( left, right: ^Expr, op: ^Token ) -> ^Expr
{
	expr := new( Logical );
	expr.type  = .Logical;
	expr.left  = left;
	expr.right = right;
	expr.op    = op;
	return expr;
}

error_stmt :: proc (p: ^Parser, error: string) -> ^Stmt
{
	// if global_error == nil
	// {
	// 	stmt := new( Error_Stmt );
	// 	stmt.type = .Error;
	// 	stmt.error = error;
	// 	stmt.token = peek(p);
	// 	global_error = stmt;
	// }
	stmt := new( Error_Stmt );
	stmt.type = .Error;
	stmt.error = error;
	stmt.token = previous(p);

	sync_after_error(p);
	return stmt;
}  

error_expr :: proc (p: ^Parser, error: string) -> ^Expr
{
	// if global_error == nil
	// {
	// 	stmt := new( Error_Stmt );
	// 	stmt.type = .Error;
	// 	stmt.error = error;
	// 	stmt.token = peek(p);
	// 	global_error = stmt;
	// }

	expr := new( Error_Expr );
	expr.type = .Error;
	expr.error = error;
	expr.token = peek(p);
	sync_after_error(p);
	return expr;
}  

make_auto_token :: proc ( current: ^Token ) -> ^Token
{
	tk := new( Token );
	tk.type = .AUTO;
	tk.line = current.line;
	tk.text = current.text;
	return tk;
}

make_noop_expr :: proc (current: ^Token) -> ^Expr
{
	expr := new( Noop );
	expr.type = .Noop;
	return expr;
}