%{
	#include <stdio.h>
	#include <math.h>
	#include <string.h>
	#include "y.tab.h"
%}

SINGLELINE_COMMENT	\/\/.*
MULTILINE_COMMENT	\/\*([^*]|[\r\n]|(\*+([^*/]|[\r\n])))*\*\/
ID 					[_a-zA-Z][_a-zA-Z0-9]*
DIGIT_SEQUENCE 		[0-9]+
INTEGER_CONST		[1-9]{DIGIT_SEQUENCE}*|0
FRACTIONAL_CONST	[0-9]*?\.{DIGIT_SEQUENCE}|{DIGIT_SEQUENCE}\.
EXPONENT_PART		[Ee][+-]?{DIGIT_SEQUENCE}
FLOATING_CONST		{FRACTIONAL_CONST}{EXPONENT_PART}?|{DIGIT_SEQUENCE}{EXPONENT_PART}
ENUMERATION_CONST	{ID}
ESCAPE_SEQUENCE		\\['"?\\abfnrtv]
C_CHAR				[^'\\\n]|{ESCAPE_SEQUENCE}
C_CHAR_SEQUENCE		{C_CHAR}+
CHARACTER_CONST		\'{C_CHAR_SEQUENCE}\'
S_CHAR				[^"\\\n]|{ESCAPE_SEQUENCE}
S_CHAR_SEQUENCE		{S_CHAR}+
STRING_LITERAL		\"{S_CHAR_SEQUENCE}?\"

%%
"auto"				{return AUTO;}
"break"				{return BREAK;}
"case"				{return CASE;}
"char"				{return CHAR;}
"const"				{return CONST;}
"continue"			{return CONTINUE;}
"default"			{return DEFAULT;}
"do"				{return DO;}
"double"			{return DOUBLE;}
"else"				{return ELSE;}
"enum"				{return ENUM;}
"extern"			{return EXTERN;}
"float"				{return FLOAT;}
"for"				{return FOR;}
"goto"				{return GOTO;}
"if"				{return IF;}
"inline"			{return INLINE;}
"int"				{return INT;}
"long"				{return LONG;}
"register"			{return REGISTER;}
"restrict"			{return RESTRICT;}
"return"			{return RETURN;}
"short"				{return SHORT;}
"signed"			{return SIGNED;}
"sizeof"			{return SIZEOF;}
"static"			{return STATIC;}
"struct"			{return STRUCT;}
"switch"			{return SWITCH;}
"typedef"			{return TYPEDEF;}
"union"				{return UNION;}
"unsigned"			{return UNSIGNED;}
"void"				{return VOID;}
"volatile"			{return VOLATILE;}
"while"				{return WHILE;}
"_Bool"				{return BOOL;}
"_Complex"			{return COMPLEX;}
"_Imaginary"		{return IMAGINARY;}
{SINGLELINE_COMMENT} {}
{MULTILINE_COMMENT}	{}
{ID}				{return ID;}
{INTEGER_CONST}		{yylval.intval=atoi(yytext);
					return INT_NO;}
{FLOATING_CONST}	{return FLOAT_NO;}
{CHARACTER_CONST}	{return CHARACTER;}
{STRING_LITERAL}	{return STRING;}
"["					{return LEFT_SQUARE_BRACE;}
"]"					{return RIGHT_SQUARE_BRACE;}
"("					{return LEFT_ROUND_BRACE;}
")"					{return RIGHT_ROUND_BRACE;}
"{"					{return LEFT_CURLY_BRACE;}
"}"					{return RIGHT_CURLY_BRACE;}
"."					{return PERIOD;}
"->"				{return ARROW;}
"++"				{return INCREMENT;}
"--"				{return DECREMENT;}
"&"					{return AMPERSAND;}
"*"					{return MULTIPLY;}
"+"					{return ADD;}
"-"					{return SUBTRACT;}
"~"					{return TILDA;}
"!"					{return NEGATION;}
"/"					{return FORWARDSLASH;}
"%"					{return PERCENTILE;}
"<<"				{return LEFT_SHIFT;}
">>"				{return RIGHT_SHIFT;}
"<"					{return LESS_THAN;}
">"					{return GREATER_THAN;}
"<="				{return LESS_THAN_EQUALTO;}
">="				{return GREATER_THAN_EQUALTO;}
"=="				{return DOUBLE_EQUAL;}
"!="				{return NOT_EQUAL;}
"^"					{return XOR;}
"|"					{return OR;}
"&&"				{return BINARY_AND;}
"||"				{return BINARY_OR;}
"?"					{return QUESTION_MARK;}
":"					{return COLON;}
";"					{return SEMI_COLON;}
"..."				{return ELLIPSIS;}
"="					{return EQUAL;}
"*="				{return STAR_EQUAL;}
"/="				{return SLASH_EQUAL;}
"%="				{return PERCENTILE_EQUAL;}
"+="				{return PLUS_EQUAL;}
"-="				{return MINUS_EQUAL;}
"<<="				{return LEFT_SHIFT_EQUAL;}
">>="				{return RIGHT_SHIFT_EQUAL;}
"&="				{return AND_EQUAL;}
"^="				{return XOR_EQUAL;}
"|="				{return OR_EQUAL;}
","					{return COMMA;}
"#"					{return HASH;}
%%