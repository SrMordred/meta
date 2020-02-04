package token

Token_Type :: enum 
{
	ID,
	INT, 
	FLOAT, 
	STRING,

	LEFT_PAREN,
	RIGHT_PAREN,
	LEFT_BRACE,
	RIGHT_BRACE,

	STAR,
	SLASH,
	PLUS,
	MINUS,

	COLON,
	SEMICOLON,
	COMMA,
	DOT,

	OR,
	AND,

	BITOR,
	BITAND,

	NOT,
	EQUAL,

	NOT_EQUAL,
	EQUAL_EQUAL,

	GREATER,
	GREATER_EQUAL,
	LESS,
	LESS_EQUAL,

	IF,
	ELSE,
	WHILE,

	EOF,

	AUTO, //token for automatic type detection
}

Token :: struct
{
	type: Token_Type,
	text: string,
	line: u32,
	col:  u32
}

