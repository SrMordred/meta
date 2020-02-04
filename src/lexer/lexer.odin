package lexer;

import "core:fmt";
import "core:os";
import "core:mem";

import "lib:token"

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
	line: u32,
	col: u32,
	tokens: [dynamic]Token
}

advance :: proc ( l: ^Lexer ) -> u8
{
	result := l.current^;
	l.current = mem.ptr_offset( l.current, 1 );
	l.col += 1;
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

make_token :: proc ( l: ^Lexer, type : Token_Type )
{
	append( &l.tokens, 
		Token
		{
			type = type,
			text = to_text( l.start, l.current ),
			line = u32(l.line),
			col  = l.col
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

	if id == "if" do make_token( l, .IF );
	else if id == "else" do make_token( l, .ELSE );
	else if id == "while" do make_token( l, .WHILE );
	else do make_token(l, .ID);
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
	make_token(l, type);
}

number_float :: proc ( l :^Lexer )
{
	advance(l);
	for is_digit( peek( l ) ) do advance( l );

	make_token(l, .FLOAT);
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

	make_token(l, .STRING);
}

comment_line :: proc (l: ^Lexer)
{
	for 
	{
		c := peek(l);
		if c == '\n' { l.col = 1; break; }
		if c == 0 do break;
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

	if len(bytes) == 0
	{
		lexer := Lexer{};
		make_token( &lexer, .EOF );
		return lexer.tokens[:];
	} 

	lexer := Lexer
	{
		start   = &bytes[0],
		current = &bytes[0],
		line    = 1,
		col     = 1,
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

			case '(': make_token( l, .LEFT_PAREN );
			case ')': make_token( l, .RIGHT_PAREN );
			case '{': make_token( l, .LEFT_BRACE );
			case '}': make_token( l, .RIGHT_BRACE );

			case '+': make_token( l, .PLUS );
			case '-': make_token( l, .MINUS );
			case '*': make_token( l, .STAR );
			case '/': 
				if match(l,'/') do comment_line(l); //comments dont generate tokens for now
				else if match(l,'*') do comment_block(l);
				else do make_token(l, .SLASH);

			case '!': make_token( l, match(l,'=') ? .NOT_EQUAL : .NOT );
			case '=': make_token( l, match(l,'=') ? .EQUAL_EQUAL : .EQUAL );
			case '<': make_token( l, match(l,'=') ? .LESS_EQUAL : .LESS );
			case '>': make_token( l, match(l,'=') ? .GREATER_EQUAL : .GREATER );

			case '&': make_token( l, match(l, '&') ? .AND : .BITAND );
			case '|': make_token( l, match(l, '|') ? .OR : .BITOR );

			case ';': make_token( l, .SEMICOLON );
			case ':': make_token( l, .COLON );
			case ',': make_token( l, .COMMA );
			case '.': 
				if is_digit( peek(l) ) do number_float( l );
				else do make_token( l, .DOT );

			case ' ','\r','\t':;

			case '\n': 
				l.line += 1;
				l.col = 1;

			case '"' : _string( l );

			case 0:
				make_token( l, .EOF );
				break OUT;

			case:
				error(l, "Unexpected character.");
		}
	}
	return l.tokens[:];
}
