package parser;

import "meta:token"
import "core:mem"
import "core:fmt"

Token :: token.Token;
Token_Type :: token.Token_Type;

print :: fmt.println;
printf :: fmt.printf;

Parser :: struct
{
	current:^Token
}

Stmt_Type :: enum
{
	Var_Decl,
	Var_Assign,
	Expr_Stmt,
	Block,
	If,
	Error
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
	var: ^Token,
	init: ^Expr
}

Var_Assign :: struct
{
	using node: Stmt,
	var: ^Token,
	init: ^Expr	
}

Expr_Type :: enum
{
	Binary,
	Unary,
	Grouping,
	Literal,
	Var,
	Error
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

make_error :: proc ( error : string, token:^Token ) -> ^Expr
{
	expr := new( Error_Expr );
	expr.type = .Error;
	expr.error = error;
	expr.token = token;
	return expr;	
}

make_var_decl :: proc ( var: ^Token, init: ^Expr ) -> ^Stmt
{
	stmt := new( Var_Decl );
	stmt.type = .Var_Decl;
	stmt.var  = var;
	stmt.init = init;
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

run :: proc ( tokens: []Token ) -> []^Stmt
{
	parser := Parser
	{ 
		current = &tokens[0]
	};

	stmts :[dynamic]^Stmt;
	c := 0;
	for parser.current.type != .EOF
	{
		append(&stmts, declaration( &parser ));
		if c == 100
		{
			print("Infinite Loop: ");
			print(stmts);
			break;
		} 
		c += 1;
	}
	return stmts[:];
}

match :: proc (p: ^Parser, types: ..Token_Type) -> bool
{
    for type in types
    {           
		if check(p, type)
		{                     
        	advance(p);                           
        	return true;                         
      	}                                      
    }
    return false;                            
}

check :: proc (p: ^Parser, type: Token_Type)  -> bool
{
    if (is_eof_tk( p )) do return false;         
    return peek( p ).type == type;          
} 

advance :: proc (p: ^Parser) -> ^Token
{   
	previous_tk := p.current;
    if (!is_eof_tk(p))
    {
    	p.current = mem.ptr_offset(p.current, 1);
	} 
    return previous_tk;
}  

previous :: proc ( p: ^Parser ) -> ^Token
{       
 	return mem.ptr_offset( p.current, -1 );
}

is_eof_tk :: proc ( p: ^Parser ) -> bool
{      
    return peek( p ).type == .EOF;     
}

peek :: proc (p: ^Parser) -> ^Token
{           
    return p.current;
}  

peek_next :: proc (p: ^Parser) -> ^Token
{           
    return mem.ptr_offset( p.current, 1 );
}  

consume :: proc(p: ^Parser, type: Token_Type) -> (^Token, bool)
{
    if (check(p, type)) do return advance(p), true;
    return {}, false;
}

error_stmt :: proc (p: ^Parser, error: string) -> ^Stmt
{
	stmt := new( Error_Stmt );
	stmt.type = .Error;
	stmt.error = error;
	stmt.token = peek(p);
	sync_after_error(p);
	return stmt;
}  

error_expr :: proc (p: ^Parser, error: string) -> ^Expr
{
	expr := new( Error_Expr );
	expr.type = .Error;
	expr.error = error;
	expr.token = peek(p);
	sync_after_error(p);
	return expr;
}  

declaration :: proc ( p: ^Parser ) -> ^Stmt
{
	if match(p, .ID)
	{
		id := previous(p);

		if match(p , .COLON_COLON) // id :: decl
		{
			// if match( p, .PROC )
			// {
			// 	return function(p);
			// }

			return error_stmt(p, "Var declaration expected!");

		}

		if match(p, .DEFINE) // id := expr;
		{
			expr := expression(p);
			if err_tk, ok := consume( p, .SEMICOLON ) ; !ok
			{
				return error_stmt( p,"Expected ; at end of declaration." );
			}
			return make_var_decl(id, expr);
		}

		if match(p, .EQUAL ) // id = expr;
		{
			expr := expression(p);
			if err_tk, ok := consume( p, .SEMICOLON ) ; !ok
			{
				return error_stmt( p,"Expected ; at end of declaration." );
			}
			return make_var_assign(id, expr);	
		}

		return error_stmt(p, "Var declaration expected!");
	}
	return statement(p);
}

var_decl :: proc (p: ^Parser) -> ^Stmt
{
	if match(p, .ID)
	{
		id := previous(p);
		if match(p, .DEFINE)
		{
			expr := expression(p);
			if err_tk, ok := consume( p, .SEMICOLON ) ; !ok
			{
				return error_stmt( p,"Expected ; at end of declaration." );
			}
			return make_var_decl(id, expr);
		}
	}
	return error_stmt(p, "Variable declaration expected.");
}

var_assign :: proc (p: ^Parser) -> ^Stmt
{
	if match(p, .ID)
	{
		id := previous(p);
		if match(p, .EQUAL)
		{
			expr := expression(p);
			if err_tk, ok := consume( p, .SEMICOLON ) ; !ok
			{
				return error_stmt( p,"Expected ; at end of declaration." );
			}
			return make_var_assign(id, expr);
		}
	}
	return error_stmt(p, "Variable assignment expected.");
}


statement :: proc (p: ^Parser) -> ^Stmt
{
	if match( p, .LEFT_BRACE )
	{
		return block(p);
	}

	if match(p, .IF)
	{
		return if_stmt(p);
	}

	if peek_next(p).type == .DEFINE 
	{
		return var_decl(p);
	}

	if peek_next(p).type == .EQUAL 
	{
		return var_assign(p);
	}

	return expression_stmt( p );
}

if_stmt :: proc (p: ^Parser) -> ^Stmt
{
	expr := expression(p);
	stmt := statement(p);
	_else: ^Stmt;

	if match(p, .ELSE)
	{

		_else = statement(p);
	}
	return make_if(expr, stmt, _else);
}

block :: proc (p: ^Parser) -> ^Stmt
{                      
    stmts : [dynamic]^Stmt;

    for !check(p, .RIGHT_BRACE) && !is_eof_tk(p)
    {     
    	append(&stmts, declaration(p));
    }            

    if err_tk, ok := consume( p, .RIGHT_BRACE ) ; !ok
	{
		return error_stmt( p,"Expected } after scope block." );
	}
    return make_block(stmts[:]);
}    

expression_stmt :: proc (p: ^Parser) -> ^Stmt
{
	expr := expression(p);
	if err_tk, ok := consume( p, .SEMICOLON ) ; !ok
	{
		return error_stmt(p, "Expected ; after expression.");
	}
	return make_expr_stmt(expr);
}

function :: proc (p: ^Parser) -> ^Stmt
{
	return nil;
}

expression :: proc ( p: ^Parser ) -> ^Expr
{
	return equality( p );
}

equality :: proc ( p: ^Parser ) -> ^Expr
{
    expr := comparison(p);

    for match ( p, .NOT_EQUAL, .EQUAL_EQUAL )
    {
    	op    := previous(p);
    	right := comparison(p);
    	expr   = make_binary( expr, right, op );
    }
    return expr;
}

comparison :: proc (p: ^Parser) -> ^Expr
{            
	expr := addition(p);

	for match(p, .GREATER, .GREATER_EQUAL, .LESS, .LESS_EQUAL)
	{
		op 		:= previous(p);                           
		right  	:= addition(p);                               
		expr  	= make_binary( expr, right, op );
	}                                                        
	return expr;                                             
} 

addition :: proc (p: ^Parser) -> ^Expr
{         
	expr := multiplication(p);

	for match(p, .MINUS, .PLUS)
	{
		op 	:= previous(p);                           
		right := multiplication(p);                               
		expr  = make_binary( expr, right, op );         
	}                                                        
	return expr;                                             
} 

multiplication :: proc (p: ^Parser) -> ^Expr
{                                
	expr := unary(p);

	for match(p, .SLASH, .STAR)
	{
	  op 	:= previous(p);                           
	  right := unary(p);                               
	  expr  = make_binary( expr, right, op );         
	}                                                        
	return expr;                                             
} 

unary :: proc ( p: ^Parser ) -> ^Expr
{                    
    if match(p, .NOT, .MINUS)
    {                
		op    	:= previous(p);           
		right 	:= unary(p);    
		return make_unary( right, op );
    }
    return primary(p);                        
}  

primary :: proc (p: ^Parser) -> ^Expr
{        
    if match(p, .INT, .FLOAT, .STRING)
    {           
      	return make_literal( previous(p) );         
    }                                                      
    else if match(p, .LEFT_PAREN)
    {                               
		expr := expression(p);                            
		err_token, ok := consume(p, .RIGHT_PAREN);
		if !ok do return make_error( "Expect ')' after expression.", err_token );
		return make_grouping(expr);                      
    }      
    else if match(p, .ID)
    {
    	return make_var( previous(p) );
    }
    error := make_error( "Unexpected primary expression.", previous(p) );

    sync_after_error(p);

    return error;
} 

sync_after_error :: proc ( p : ^Parser )
{
	for 
	{
		tk_type := peek(p).type;
		if tk_type == .SEMICOLON { advance(p); return; }
		if tk_type == .EOF { return; }
		advance(p);
	}
}