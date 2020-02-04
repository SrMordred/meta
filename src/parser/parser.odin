package parser;

import "lib:token"
import "core:mem"
import "core:fmt"

Token :: token.Token;
Token_Type :: token.Token_Type;

print :: fmt.println;
printf :: fmt.printf;
f :: fmt.tprintf;

Parser :: struct
{
	current:^Token
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

declaration :: proc ( p: ^Parser ) -> ^Stmt
{
	return statement(p);
}

var_decl :: proc ( p: ^Parser, id:^Token ) -> ^Stmt
{
	if match(p , .ID)
	{
		var_type := previous(p);
		expr: ^Expr;
		if match(p, .EQUAL)
		{
			expr = expression(p);
		}

		if err_tk, ok := consume( p, .SEMICOLON ) ; !ok
		{
			return error_stmt( p,"Expected ; at end of declaration." );
		}
		return make_var_decl(id, var_type, expr);
	}
	else if match(p, .EQUAL)
	{
		expr := expression(p);
		if err_tk, ok := consume( p, .SEMICOLON ) ; !ok
		{
			return error_stmt( p,"Expected ; at end of declaration." );
		}
		return make_var_decl(id, make_auto_token(id) , expr);
	}
	return error_stmt( p,"Expected declaration or assignment." );
}

var_assign :: proc (p: ^Parser, id: ^Token) -> ^Stmt
{
	expr := expression(p);
	if err_tk, ok := consume( p, .SEMICOLON ) ; !ok
	{
		return error_stmt( p,"Expected ; at end of declaration." );
	}
	return make_var_assign(id, expr);
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

	if match(p, .WHILE)
	{
		return while_stmt(p);
	}

	if match(p, .ID)
	{
		id := previous(p);

		if match(p, .COLON) // id : type = expr;
		{
			return var_decl( p, id );
		}
		else if match(p, .EQUAL)//id = expr;
		{
			return var_assign(p, id);
		}
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

while_stmt :: proc (p: ^Parser) -> ^Stmt
{
	expr := expression(p);
	stmt := statement(p);
	return make_while( expr, stmt );
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
	return or( p );
}

or :: proc (p : ^Parser) -> ^Expr
{
	expr := and(p);
    for  match(p, .OR)
    {           
    	op    := previous(p);
    	right := and(p);
    	expr   = make_logical( expr, right, op );                   
    }                                                
    return expr;  
}

and :: proc (p : ^Parser) -> ^Expr
{
	expr := equality(p);
    for  match(p, .AND)
    {           
    	op    := previous(p);
    	right := and(p);
    	expr   = make_logical( expr, right, op );                   
    }                                                
    return expr;  
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
	// print(peek(p));
    if match(p, .INT, .FLOAT, .STRING)
    {           
      	return make_literal( previous(p) );         
    }                                                      
    else if match(p, .LEFT_PAREN)
    {                               
		expr := expression(p);                            
		err_token, ok := consume(p, .RIGHT_PAREN);
		if !ok do return error_expr(p, "Expect ')' after expression." );
		return make_grouping(expr);                      
    }      
    else if match(p, .ID)
    {
    	return make_var( previous(p) );
    }
    // else if peek(p).type == .SEMICOLON
    // {
    // 	return make_noop_expr( previous(p) );
    // }
    error := error_expr(p, "Unexpected primary expression" );

    return error;
} 

sync_after_error :: proc ( p : ^Parser )
{
	for 
	{
		tk_type := peek(p).type;
		if tk_type == .SEMICOLON { return; }
		if tk_type == .EOF { return; }
		advance(p);
	}
}