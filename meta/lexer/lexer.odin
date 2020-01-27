package lexer;

import "core:fmt";
import "core:os";
import "core:mem";

import "meta:token"

print :: fmt.println;
printf :: fmt.printf;

Token :: token.Token;
Token_Type :: token.Token_Type;


read_file :: proc ( name : string ) -> (data: []byte, success: bool) 
{
	fd, err := os.open(name, os.O_RDONLY, 0);
	if err != 0 {
		return nil, false;
	}
	defer os.close(fd);

	length: i64;
	if length, err = os.file_size(fd); err != 0 {
		return nil, false;
	}

	if length <= 0 {
		return nil, true;
	}

	data = make([]byte, int(length) + 1);
	if data == nil {
		return nil, false;
	}

	bytes_read, read_err := os.read(fd, data);
	if read_err != 0 {
		delete(data);
		return nil, false;
	}
	data[bytes_read] = 0;
	return data[0:bytes_read + 1], true;
}


is_alpha :: inline proc ( char: u8 ) -> bool
{
	return 
	char >= 'a' && char <='z' ||
	char >= 'A' && char <='Z' ||
	char == '_';
}

is_digit :: inline proc ( char: u8 ) -> bool
{
	return char >= '0' && char <='9';	
}

is_alphanumeric :: inline proc( char: u8 ) -> bool
{
	return is_alpha(char) || is_digit(char);
}

is_eof :: inline proc ( char: u8 ) -> bool
{
	return char == 0;
}

char_diff :: proc ( old:^u8, new: ^u8) -> int
{
	return cast(int) (uintptr(new) - uintptr(old));
}

to_text_len :: proc ( char:^u8, len:int ) -> string
{
	return string( mem.slice_ptr(char, len) );
}

to_text_diff :: proc ( char:^u8, end:^u8 ) -> string
{
	return string( mem.slice_ptr(char,  char_diff(char, end) ) );
}

to_text :: proc{ to_text_len, to_text_diff };


Lexer :: struct
{
	start: ^u8,
	current:^u8,
	line: int,
	tokens: [dynamic]Token
}

advance :: proc ( l: ^Lexer ) -> u8
{
	result := l.current^;
	l.current = mem.ptr_offset( l.current, 1 );
	return result;
}

match :: proc (l: ^Lexer, char: u8 ) -> bool
{
	if l.current^ != char do return false;
	l.current = mem.ptr_offset( l.current, 1 );
	return true;
}

peek :: proc ( l: ^Lexer ) -> u8
{
	return l.current^;
}

peek_next :: proc ( l: ^Lexer ) -> u8
{
	if l.current^ == 0 do return 0;
	return mem.ptr_offset( l.current, 1 )^;
}

token_create :: proc ( l: ^Lexer, type : Token_Type )
{
	append( &l.tokens, 
		Token
		{
			type = type,
			text = to_text( l.start, l.current ),
			line = l.line
		});
}

//	 there must be a better way to remove spaces in my l ...
remove_whitespace :: proc ( l: ^Lexer )
{
	char := peek( l );
	for char == ' ' || char == '\t' || char == '\n'
	{
		char = advance( l );
	} 
}

identifier :: proc ( l: ^Lexer )
{
	for is_alphanumeric( peek( l ) )
		do advance( l );

	id := to_text( l.start, l.current );

	if id == "if" do token_create( l, .IF );
	else if id == "else" do token_create( l, .ELSE );
	else do token_create(l, .ID);
}

number :: proc ( l :^Lexer )
{
	for is_digit( peek( l ) ) do advance( l );
	type:Token_Type = .INT;
	if peek(l) == '.' 
	{
		type = .FLOAT;
		advance(l);
		for is_digit( peek( l ) ) do advance( l );
	}
	token_create(l, type);
}

number_float :: proc ( l :^Lexer )
{
	advance(l);
	for is_digit( peek( l ) ) do advance( l );

	token_create(l, .FLOAT);
}

_string :: proc ( l: ^Lexer )
{
	for
	{
		c:= peek(l);
		if c == 0 do error(l, "Unexpected end of file.");
		if c == '\n' do error(l, "Strings cant\'t have line breaks. Use string literals.");
		if c == '"' do break;
		advance(l);
	}

	token_create(l, .STRING);
}

comment_line :: proc (l: ^Lexer)
{
	for 
	{
		c := peek(l);
		if c == '\n' || c == 0 do break;
		advance(l);
	}
}

comment_block :: proc (l: ^Lexer)
{
	for 
	{
		c := peek(l);

		if c == 0 do break;
		if c == '*' 
		{
			next_c := peek_next(l);
			if next_c == '/' || next_c == 0 do break;
		}
		advance(l);
	}
}

error :: proc ( l:^Lexer, msg: string )
{
	print(msg);
	print("at: '%v'", l.current^);
}

run :: proc ( file:string ) -> []Token
{
	bytes, ok := read_file( file );

	if !ok 
	{
		print( "l failed to open file :", file );
		return {};
	}

	lexer := Lexer
	{
		start   = &bytes[0],
		current = &bytes[0],
		line    = 1,
		tokens  = make([dynamic]Token, 0,32)
	};

	l := &lexer;

	OUT: for
	{
		l.start = l.current;
		char := advance( l );
		switch char
		{
			case 'a'..'z', 'A'..'Z', '_': identifier( l );
			case '0' .. '9' : number( l );

			case '(': token_create( l, .LEFT_PAREN );
			case ')': token_create( l, .RIGHT_PAREN );
			case '{': token_create( l, .LEFT_BRACE );
			case '}': token_create( l, .RIGHT_BRACE );

			case '+': token_create( l, .PLUS );
			case '-': token_create( l, .MINUS );
			case '*': token_create( l, .STAR );
			case '/': 
				if match(l,'/') do comment_line(l); //comments dont generate tokens for now
				else if match(l,'*') do comment_block(l);
				else do token_create(l, .SLASH);

			case '!': token_create( l, match(l,'=') ? .NOT_EQUAL : .NOT );
			case '=': token_create( l, match(l,'=') ? .EQUAL_EQUAL : .EQUAL );
			case '<': token_create( l, match(l,'=') ? .LESS_EQUAL : .LESS );
			case '>': token_create( l, match(l,'=') ? .GREATER_EQUAL : .GREATER );

			case ';': token_create( l, .SEMICOLON );
			case ':': 
			// :: , := , : 
			token_create( l, 
				match(l,':') ?
				.COLON_COLON : 
				( match(l,'=') ?
				  .DEFINE : 
				  .COLON ));
			case ',': token_create( l, .COMMA );
			case '.': 
				if is_digit( peek(l) ) do number_float( l );
				else do token_create( l, .DOT );

			case ' ','\r','\t':;

			case '\n': l.line += 1;

			case '"' : _string( l );

			case 0:
				token_create( l, .EOF );
				break OUT;

			case:
				error(l, "Unexpected character.");
		}
	}
	return l.tokens[:];
}
