%{
#include <stdio.h>
#include <iostream>
#include <vector>
#include <algorithm>
#include <utility>
#include <string>
#include <cstring>
#include <fstream>
#include "translator.h"
extern int yylex();
extern char* yytext;
extern symbol_table* globalST;
extern symbol_table* currentST;
extern vector<string> string_label;
int globaloffset=0,store_type;
int currentoffset=0;
void yyerror(char *s);
row* int2bool(row *r);
row* char2int(row* r);
row* int2doub(row* r);
row* char2doub(row* r);
row* doub2int(row* r);
string id_name;
vector<string> par_list;
string func_name;
string array_temp_name;
string array_name;
%}

%code requires {
#include "translator.h"}

%union{
    int intval;
	char* stringval;
	char charval;
	double floatval;
	struct row* RO;
	symbol_table* SYT;
}

%token AUTO
%token BREAK 
%token CASE 
%token CHAR
%token CONST 
%token CONTINUE
%token DEFAULT
%token DO
%token DOUBLE
%token ELSE
%token ENUM
%token EXTERN
%token FLOAT
%token FOR
%token GOTO
%token IF
%token INLINE
%token INT
%token LONG
%token REGISTER
%token RESTRICT
%token RETURN
%token SHORT
%token SIGNED
%token SIZEOF
%token STATIC
%token STRUCT
%token SWITCH
%token TYPEDEF
%token UNION
%token UNSIGNED
%token VOID
%token VOLATILE
%token WHILE
%token BOOL
%token COMPLEX
%token IMAGINARY
%token SINGLE_COMMENT
%token MULTI_COMMENT
%token <stringval> ID
%token <intval> INT_NO
%token <floatval> FLOAT_NO
%token <charval> CHARACTER
%token <stringval> STRING
%token LEFT_SQUARE_BRACE
%token RIGHT_SQUARE_BRACE
%token LEFT_ROUND_BRACE
%token RIGHT_ROUND_BRACE
%token LEFT_CURLY_BRACE
%token RIGHT_CURLY_BRACE
%token PERIOD
%token ARROW
%token INCREMENT
%token DECREMENT
%token AMPERSAND
%token MULTIPLY
%token ADD
%token SUBTRACT
%token TILDA
%token NEGATION
%token FORWARDSLASH
%token PERCENTILE
%token LEFT_SHIFT
%token RIGHT_SHIFT
%token LESS_THAN
%token GREATER_THAN
%token LESS_THAN_EQUALTO
%token GREATER_THAN_EQUALTO
%token DOUBLE_EQUAL
%token NOT_EQUAL
%token XOR
%token OR
%token BINARY_AND
%token BINARY_OR
%token QUESTION_MARK
%token COLON
%token SEMI_COLON
%token ELLIPSIS
%token EQUAL
%token STAR_EQUAL
%token SLASH_EQUAL
%token PERCENTILE_EQUAL
%token PLUS_EQUAL
%token MINUS_EQUAL
%token LEFT_SHIFT_EQUAL
%token RIGHT_SHIFT_EQUAL
%token AND_EQUAL
%token XOR_EQUAL
%token OR_EQUAL
%token COMMA
%token HASH

%nonassoc THEN
%nonassoc ELSE

%type <intval> declaration_specifiers type_specifier specifier_qualifier_list type_name M
%type <RO> postfix_expression unary_expression cast_expression N argument_expression_list argument_expression_listopt
%type <RO> multiplicative_expression additive_expression shift_expression relational_expression equality_expression
%type <RO> AND_expression exclusive_OR_expression inclusive_OR_expression logical_AND_expression logical_OR_expression
%type <RO> conditional_expression assignment_expression assignment_expressionopt initializer
%type <RO> init_declarator_list primary_expression expression constant_expression
%type <RO> statement compound_statement block_item_list block_item expression_statement selection_statement iteration_statement
%type <RO> jump_statement block_item_listopt expressionopt array_exp
%type <RO> declaration init_declarator function_definition
%type <RO> declarator direct_declarator bool_expression bool_expressionopt
%type <charval> unary_operator
%type <SYT> funcdecstart funcdecend
%left '+' '-'
%left '*' '/'

%start translation_unit

%%

primary_expression:
				  	ID
				  		{
				  			$$=currentST->lookup(yytext);
				  			$$->isconst=false;
				  			id_name=yytext;
				  		}
				  	|INT_NO
				  		{
							$$=symbol_table::gentemp(*currentST);
				  			id_name=$$->Name;
							$$->isBoolExp=false;
							$$->init_val=yytext;
							$$->size=4;
							$$->isconst=true;
							$$->offset=currentoffset;
							$$->Typ=inttype;
							$$->isArray=false;
							currentoffset+=4;
							quad_array.push_back(quad($$->Name,yytext));
						}
				  	|FLOAT_NO
				  		{
							$$=symbol_table::gentemp(*currentST);
				  			id_name=$$->Name;
							$$->isBoolExp=false;
							$$->isconst=true;
							$$->init_val=yytext;
							$$->size=8;
							$$->offset=currentoffset;
							$$->Typ=doubletype;
							$$->isArray=false;
							currentoffset+=8;
							quad_array.push_back(quad($$->Name,yytext));
				  		}
				  	|STRING
				  		{
				  			$$=symbol_table::gentemp(*currentST);
				  			id_name=$$->Name;
							$$->isBoolExp=false;
							$$->isconst=true;
                    		$$->init_val=yytext;
                    		$$->offset=currentoffset;
                    		$$->Typ=stringtype;
                    		$$->size=8;
							$$->isArray=false;
                    		currentoffset+=8;
							quad_array.push_back(quad($$->Name,yytext));
							string_label.push_back(yytext);
				  		}
				  	|CHARACTER
				  		{
				  			$$=symbol_table::gentemp(*currentST);
				  			id_name=$$->Name;
							$$->isBoolExp=false;
							$$->isconst=true;
							$$->init_val=yytext[1];
							$$->size=1;
							$$->offset=currentoffset;
							currentoffset+=1;
							$$->isArray=false;
							$$->Typ=chartype;
							quad_array.push_back(quad($$->Name,yytext));
				  		}
				  	|LEFT_ROUND_BRACE expression RIGHT_ROUND_BRACE
				  		{
				  			$$=$2;
				  		}
				  	;

postfix_expression:
				  primary_expression{$$=$1;}
				  |array_exp
				  	{	
				  		struct row* t=symbol_table::gentemp(*currentST);
				  		$$=symbol_table::gentemp(*currentST);
				  		int i=0;
				  		while($1->typ_vector[i].second==3&&i<$1->typ_vector.size())i++;
            			if($1->typ_vector[i].second==0){$$->Typ=ptr_int;
            			$$->size=4;}
            			if($1->typ_vector[i].second==1){$$->Typ=ptr_double;
            			$$->size=8;}
            			if($1->typ_vector[i].second==2){$$->Typ=ptr_char;
            			$$->size=1;}
            			if($1->typ_vector[i].second==9){$$->Typ=stringtype;
            			$$->size=8;}
						$$->isArray=true;
            			$$->offset=currentoffset;
            			currentoffset+=$$->size;
            			char c[30];
            			sprintf(c,"%d",$$->size);
            			string s(c);
            			quad_array.push_back(quad("*",t->Name,s,id_name));
            			array_temp_name=t->Name;
            			array_name=$1->Name;
				  	}
				  |postfix_expression LEFT_ROUND_BRACE argument_expression_listopt RIGHT_ROUND_BRACE
				  	{
				  		for(int i=0;i<par_list.size();i++)quad_array.push_back(quad("param ",par_list[i].c_str()));
				  		$$=symbol_table::gentemp(*currentST);
				  		$$->isArray=false;
				  		if(currentST->lookup($1->Name)->nestedTable!=NULL)$$->Typ=currentST->lookup($1->Name)->nestedTable->lookup("RetVal")->Typ;
				  		else $$->Typ=inttype;
				  		quad_array.push_back(quad("call",$1->Name,$$->Name,par_list.size()));
				  		par_list.clear();
				  	}
				  |postfix_expression PERIOD ID
				  |postfix_expression ARROW ID
				  |postfix_expression INCREMENT
				  	{
				  		$$=symbol_table::gentemp(*currentST);
						$$->isBoolExp=false;
				  		$$->offset=currentoffset;
				  		$$->Typ=$1->Typ;
				  		$$->size=$1->size;
				  		$$->init_val=$1->init_val;
				  		currentoffset+=$1->size;
				  		quad_array.push_back(quad($$->Name,$1->Name));
				  		quad_array.push_back(quad("+",$1->Name,$$->Name,"1"));
				  	}
				  |postfix_expression DECREMENT
				  	{
				  		$$=symbol_table::gentemp(*currentST);
						$$->isBoolExp=false;
				  		$$->offset=currentoffset;
				  		$$->Typ=$1->Typ;
				  		$$->size=$1->size;
				  		$$->init_val=$1->init_val;
				  		currentoffset+=$1->size;
				  		quad_array.push_back(quad($$->Name,$1->Name));
				  		quad_array.push_back(quad("-",$1->Name,$$->Name,"1"));
				  	}
				  |LEFT_ROUND_BRACE type_name RIGHT_ROUND_BRACE LEFT_CURLY_BRACE initializer_list RIGHT_CURLY_BRACE{}
				  |LEFT_ROUND_BRACE type_name RIGHT_ROUND_BRACE LEFT_CURLY_BRACE initializer_list COMMA RIGHT_CURLY_BRACE{}
				  ;

array_exp:
            primary_expression LEFT_SQUARE_BRACE expression RIGHT_SQUARE_BRACE
            {      	
            	if($1->typ_vector.size()==0)cout<<"Error\n";
            	else {
            		$$=$1;
            	}
            }
            |array_exp LEFT_SQUARE_BRACE expression RIGHT_SQUARE_BRACE
            	{
            		if($1->typ_vector.size()==0)cout<<"Error\n";
            		else {
            		struct row* t=symbol_table::gentemp(*currentST);
            		$$=symbol_table::gentemp(*currentST);
            		char c[30];
            		sprintf(c,"%d",$1->typ_vector[1].first);
            		string s(c);
            		quad_array.push_back(quad("*",t->Name,$1->Name,s));
            		quad_array.push_back(quad("+",$$->Name,t->Name,$3->Name));
            		int i=1;
            		while(i<$1->typ_vector.size()){$$->typ_vector.push_back($1->typ_vector[i]);i++;}
            		}
            	}
            ;

argument_expression_listopt:
						  argument_expression_list{$$=$1;}
						  |{}
						  ;

argument_expression_list:
					  assignment_expression{$$=$1;par_list.push_back($1->Name);}
					  |argument_expression_list COMMA assignment_expression{$$=$1;par_list.push_back($3->Name);}
					  ;

unary_expression:
				postfix_expression{$$=$1;}
				|INCREMENT unary_expression
					{
				  		quad_array.push_back(quad("+",$2->Name,$2->Name,"1"));
						$$=symbol_table::gentemp(*currentST);
						$$->isBoolExp=false;
				  		$$->offset=currentoffset;
				  		$$->Typ=$2->Typ;
				  		$$->size=$2->size;
				  		$$->init_val=$2->init_val;
				  		currentoffset+=$2->size;
				  		quad_array.push_back(quad($$->Name,$2->Name));
					}
				|DECREMENT unary_expression
					{
						$$=symbol_table::gentemp(*currentST);
						$$->isBoolExp=false;
				  		$$->offset=currentoffset;
				  		$$->Typ=$2->Typ;
				  		$$->size=$2->size;
				  		$$->init_val=$2->init_val;
				  		currentoffset+=$2->size;
				  		quad_array.push_back(quad("-",$2->Name,$2->Name,"1"));
				  		quad_array.push_back(quad($$->Name,$2->Name));
					}
				|unary_operator cast_expression
					{
						$$=symbol_table::gentemp(*currentST);
						$$->isBoolExp=false;
						if($1=='*'){
							if($2->Typ==ptr_int)$$->Typ=inttype;
							if($2->Typ==ptr_double)$$->Typ=doubletype;
							if($2->Typ==ptr_char)$$->Typ=chartype;
						}
						else if($1=='&'){
							if($2->Typ==inttype)$$->Typ=ptr_int;
							if($2->Typ==doubletype)$$->Typ=ptr_double;
							if($2->Typ==chartype)$$->Typ=ptr_char;
						}
				  		$$->size=$2->size;
						$$->offset=currentoffset;
						currentoffset+=$2->size;
						string s(1,$1);
						quad_array.push_back(quad(s,$$->Name,$2->Name));
					}
				;					 

unary_operator:
			  AMPERSAND{$$='&';}
			  |MULTIPLY{$$='*';}
			  |ADD{$$='+';}
			  |SUBTRACT{$$='-';}
			  |TILDA{$$='~';}
			  |NEGATION{$$='!';}
			  ;

cast_expression:
			   unary_expression{$$=$1;}
			   |LEFT_ROUND_BRACE type_name RIGHT_ROUND_BRACE cast_expression
			   	{
			   		$$=$4;
			   		if($2==0)$$->Typ=inttype;
			   		if($2==1)$$->Typ=doubletype;
			   		if($2==2)$$->Typ=chartype;
			   		if($2==8)$$->Typ=voidtype;
			   	}
			   ;

multiplicative_expression:
						cast_expression{$$=$1;}
						|multiplicative_expression MULTIPLY cast_expression
							{
								int flag=1;
								if(typecheck($1,$3)!=true){
								if($1->Typ==chartype&&$3->Typ==inttype)$1=char2int($1);
								else if($3->Typ==chartype&&$1->Typ==inttype)$3=char2int($3);
								else if($1->Typ==inttype&&$3->Typ==doubletype)$1=int2doub($1);
								else if($1->Typ==doubletype&&$3->Typ==inttype)$3=int2doub($3);
								else if($1->Typ==doubletype&&$3->Typ==chartype)$3=char2doub($3);
								else if($3->Typ==doubletype&&$1->Typ==chartype)$1=char2doub($1);
								else {flag=0;}
								}
								if(flag==1){
									$$=symbol_table::gentemp(*currentST);
									$$->isBoolExp=false;
									$$->Typ=$1->Typ;
				  					$$->size=$1->size;
									$$->offset=currentoffset;
									currentoffset+=$1->size;
									string s(1,'*');
									quad_array.push_back(quad(s,$$->Name,$1->Name,$3->Name));
								}
							}
						|multiplicative_expression FORWARDSLASH cast_expression
							{
								int flag=1;
								if(typecheck($1,$3)!=true){
								if($1->Typ==chartype&&$3->Typ==inttype)$1=char2int($1);
								else if($3->Typ==chartype&&$1->Typ==inttype)$3=char2int($3);
								else if($1->Typ==inttype&&$3->Typ==doubletype)$1=int2doub($1);
								else if($1->Typ==doubletype&&$3->Typ==inttype)$3=int2doub($3);
								else if($1->Typ==doubletype&&$3->Typ==chartype)$3=char2doub($3);
								else if($3->Typ==doubletype&&$1->Typ==chartype)$1=char2doub($1);
								else {flag=0;}
								}
								if(flag==1){
									$$=symbol_table::gentemp(*currentST);
									$$->isBoolExp=false;
									$$->Typ=$1->Typ;
				  					$$->size=$1->size;
									$$->offset=currentoffset;
									currentoffset+=$1->size;
									string s(1,'/');
									quad_array.push_back(quad(s,$$->Name,$1->Name,$3->Name));
								}
							}
						|multiplicative_expression PERCENTILE cast_expression
							{
								int flag=1;
								if(typecheck($1,$3)!=true){
								if($1->Typ==chartype&&$3->Typ==inttype)$1=char2int($1);
								else if($3->Typ==chartype&&$1->Typ==inttype)$3=char2int($3);
								else if($1->Typ==inttype&&$3->Typ==doubletype)$1=int2doub($1);
								else if($1->Typ==doubletype&&$3->Typ==inttype)$3=int2doub($3);
								else if($1->Typ==doubletype&&$3->Typ==chartype)$3=char2doub($3);
								else if($3->Typ==doubletype&&$1->Typ==chartype)$1=char2doub($1);
								else {flag=0;}
								}
								if(flag==1){
									$$=symbol_table::gentemp(*currentST);
									$$->isBoolExp=false;
									$$->Typ=$1->Typ;
				  					$$->size=$1->size;
									$$->offset=currentoffset;
									currentoffset+=$1->size;
									string s(1,'%');
									quad_array.push_back(quad(s,$$->Name,$1->Name,$3->Name));
								}
							}
						;

additive_expression:
				   multiplicative_expression{$$=$1;}
				   |additive_expression ADD multiplicative_expression
				   	{
				   		int flag=1;
						if(typecheck($1,$3)!=true){
						if($1->Typ==chartype&&$3->Typ==inttype)$1=char2int($1);
						else if($3->Typ==chartype&&$1->Typ==inttype)$3=char2int($3);
						else if($1->Typ==inttype&&$3->Typ==doubletype)$1=int2doub($1);
						else if($1->Typ==doubletype&&$3->Typ==inttype)$3=int2doub($3);
						else if($1->Typ==doubletype&&$3->Typ==chartype)$3=char2doub($3);
						else if($3->Typ==doubletype&&$1->Typ==chartype)$1=char2doub($1);
						else {flag=0;}
						}
						if(flag==1){
						$$=symbol_table::gentemp(*currentST);
						$$->isBoolExp=false;
						$$->Typ=$1->Typ;
				  		$$->size=$1->size;
						$$->offset=currentoffset;
						currentoffset+=$1->size;
						string s(1,'+');
						quad_array.push_back(quad(s,$$->Name,$1->Name,$3->Name));
						}
				   	}
				   |additive_expression SUBTRACT multiplicative_expression
				   	{
				   		int flag=1;
						if(typecheck($1,$3)!=true){
						if($1->Typ==chartype&&$3->Typ==inttype)$1=char2int($1);
						else if($3->Typ==chartype&&$1->Typ==inttype)$3=char2int($3);
						else if($1->Typ==inttype&&$3->Typ==doubletype)$1=int2doub($1);
						else if($1->Typ==doubletype&&$3->Typ==inttype)$3=int2doub($3);
						else if($1->Typ==doubletype&&$3->Typ==chartype)$3=char2doub($3);
						else if($3->Typ==doubletype&&$1->Typ==chartype)$1=char2doub($1);
						else {flag=0;}
						}
						if(flag==1){
						$$=symbol_table::gentemp(*currentST);
						$$->isBoolExp=false;
						$$->Typ=$1->Typ;
				  		$$->size=$1->size;
						$$->offset=currentoffset;
						currentoffset+=$1->size;
						string s(1,'-');
						quad_array.push_back(quad(s,$$->Name,$1->Name,$3->Name));
						}
				   	}
				   ;

shift_expression:
				additive_expression{$$=$1;}
				|shift_expression LEFT_SHIFT additive_expression
					{
						int flag=1;
						if(typecheck($1,$3)!=true){
						if($1->Typ==chartype&&$3->Typ==inttype)$1=char2int($1);
						else if($3->Typ==chartype&&$1->Typ==inttype)$3=char2int($3);
						else if($1->Typ==inttype&&$3->Typ==doubletype)$1=int2doub($1);
						else if($1->Typ==doubletype&&$3->Typ==inttype)$3=int2doub($3);
						else if($1->Typ==doubletype&&$3->Typ==chartype)$3=char2doub($3);
						else if($3->Typ==doubletype&&$1->Typ==chartype)$1=char2doub($1);
						else {flag=0;}
						}
						if(flag==1){
						$$=symbol_table::gentemp(*currentST);
						$$->isBoolExp=false;
						$$->Typ=$1->Typ;
				  		$$->size=$1->size;
						$$->offset=currentoffset;
						currentoffset+=$1->size;
						string s(2,'<<');
						//quad_array.push_back(quad(s,$$->Name,$1->Name,$3->Name));
						}
					}
				|shift_expression RIGHT_SHIFT additive_expression
					{
						int flag=1;
						if(typecheck($1,$3)!=true){
						if($1->Typ==chartype&&$3->Typ==inttype)$1=char2int($1);
						else if($3->Typ==chartype&&$1->Typ==inttype)$3=char2int($3);
						else if($1->Typ==inttype&&$3->Typ==doubletype)$1=int2doub($1);
						else if($1->Typ==doubletype&&$3->Typ==inttype)$3=int2doub($3);
						else if($1->Typ==doubletype&&$3->Typ==chartype)$3=char2doub($3);
						else if($3->Typ==doubletype&&$1->Typ==chartype)$1=char2doub($1);
						else {flag=0;}
						}
						if(flag==1){
						$$=symbol_table::gentemp(*currentST);
						$$->isBoolExp=false;
						$$->Typ=$1->Typ;
				  		$$->size=$1->size;
						$$->offset=currentoffset;
						currentoffset+=$1->size;
						string s(2,'>>');
						//quad_array.push_back(quad(s,$$->Name,$1->Name,$3->Name));
						}
					}
				;

relational_expression:
					 shift_expression{$$=$1;}
					 |relational_expression LESS_THAN shift_expression
					 	{
					 		$$=new struct row();
							$$->truelist=makelist(quad_array.size());
							$$->falselist=makelist(quad_array.size()+1);
							$$->isBoolExp=true;
							quad_array.push_back(quad("<","...",$1->Name,$3->Name));
							quad_array.push_back(quad("goto","...",$1->Name));
					 	}
					 |relational_expression GREATER_THAN shift_expression
					 	{
					 		$$=new struct row();
							$$->truelist=makelist(quad_array.size());
							$$->falselist=makelist(quad_array.size()+1);
							$$->isBoolExp=true;
							quad_array.push_back(quad(">","...",$1->Name,$3->Name));
							quad_array.push_back(quad("goto","...",$1->Name));
					 	}
					 |relational_expression LESS_THAN_EQUALTO shift_expression
					 	{
					 		$$=new struct row();
							$$->truelist=makelist(quad_array.size());
							$$->falselist=makelist(quad_array.size()+1);
							$$->isBoolExp=true;
							quad_array.push_back(quad("<=","...",$1->Name,$3->Name));
							quad_array.push_back(quad("goto","...",$1->Name));
					 	}
					 |relational_expression GREATER_THAN_EQUALTO shift_expression
					 	{
					 		$$=new struct row();
							$$->truelist=makelist(quad_array.size());
							$$->falselist=makelist(quad_array.size()+1);
							$$->isBoolExp=true;
							quad_array.push_back(quad(">=","...",$1->Name,$3->Name));
							quad_array.push_back(quad("goto","...",$1->Name));
					 	}
					 ;

equality_expression:
				   relational_expression{$$=$1;}
				   |equality_expression DOUBLE_EQUAL relational_expression
				   	{
				   		$$=new struct row();
						$$->truelist=makelist(quad_array.size());
						$$->falselist=makelist(quad_array.size()+1);
						$$->isBoolExp=true;
						quad_array.push_back(quad("==","...",$1->Name,$3->Name));
						quad_array.push_back(quad("goto","...",$1->Name));
				   	}
				   |relational_expression NOT_EQUAL relational_expression
				   	{
				   		$$=new struct row();
						$$->truelist=makelist(quad_array.size());
						$$->falselist=makelist(quad_array.size()+1);
						$$->isBoolExp=true;
						quad_array.push_back(quad("!=","...",$1->Name,$3->Name));
						quad_array.push_back(quad("goto","...",$1->Name));
				   	}
				   ;

AND_expression:
			  equality_expression{$$=$1;}
			  |AND_expression AMPERSAND equality_expression
			  	{
					int flag=1;
					if(typecheck($1,$3)!=true){
					if($1->Typ==chartype&&$3->Typ==inttype)$1=char2int($1);
					else if($3->Typ==chartype&&$1->Typ==inttype)$3=char2int($3);
					else if($1->Typ==inttype&&$3->Typ==doubletype)$1=int2doub($1);
					else if($1->Typ==doubletype&&$3->Typ==inttype)$3=int2doub($3);
					else if($1->Typ==doubletype&&$3->Typ==chartype)$3=char2doub($3);
					else if($3->Typ==doubletype&&$1->Typ==chartype)$1=char2doub($1);
					else {flag=0;}
					}
					if(flag==1){
					$$=symbol_table::gentemp(*currentST);
					$$->isBoolExp=false;
					$$->Typ=$1->Typ;
					$$->size=$1->size;
					$$->offset=currentoffset;
					currentoffset+=$1->size;
					string s(1,'&');
					quad_array.push_back(quad(s,$$->Name,$1->Name,$3->Name));
					}
				}
			  ;

exclusive_OR_expression:
					   AND_expression{$$=$1;}
					   |exclusive_OR_expression XOR AND_expression
					   	{
							int flag=1;
							if(typecheck($1,$3)!=true){
							if($1->Typ==chartype&&$3->Typ==inttype)$1=char2int($1);
							else if($3->Typ==chartype&&$1->Typ==inttype)$3=char2int($3);
							else if($1->Typ==inttype&&$3->Typ==doubletype)$1=int2doub($1);
							else if($1->Typ==doubletype&&$3->Typ==inttype)$3=int2doub($3);
							else if($1->Typ==doubletype&&$3->Typ==chartype)$3=char2doub($3);
							else if($3->Typ==doubletype&&$1->Typ==chartype)$1=char2doub($1);
							else {flag=0;}
							}
							if(flag==1){
							$$=symbol_table::gentemp(*currentST);
							$$->isBoolExp=false;
							$$->Typ=$1->Typ;
					  		$$->size=$1->size;
							$$->offset=currentoffset;
							currentoffset+=$1->size;
							string s(1,'^');
							quad_array.push_back(quad(s,$$->Name,$1->Name,$3->Name));
							}
						}
					   ;

inclusive_OR_expression:
					   exclusive_OR_expression{$$=$1;}
					   |inclusive_OR_expression OR exclusive_OR_expression
					   	{
							int flag=1;
							if(typecheck($1,$3)!=true){
							if($1->Typ==chartype&&$3->Typ==inttype)$1=char2int($1);
							else if($3->Typ==chartype&&$1->Typ==inttype)$3=char2int($3);
							else if($1->Typ==inttype&&$3->Typ==doubletype)$1=int2doub($1);
							else if($1->Typ==doubletype&&$3->Typ==inttype)$3=int2doub($3);
							else if($1->Typ==doubletype&&$3->Typ==chartype)$3=char2doub($3);
							else if($3->Typ==doubletype&&$1->Typ==chartype)$1=char2doub($1);
							else {flag=0;}
							}
							if(flag==1){
							$$=symbol_table::gentemp(*currentST);
							$$->isBoolExp=false;
							$$->Typ=$1->Typ;
					  		$$->size=$1->size;
							$$->offset=currentoffset;
							currentoffset+=$1->size;
							string s(1,'|');
							quad_array.push_back(quad(s,$$->Name,$1->Name,$3->Name));
							}
						}	
					   ;

logical_AND_expression:
					  inclusive_OR_expression{$$=$1;}
					  |logical_AND_expression BINARY_AND M inclusive_OR_expression
					  	{
					  		$$=new struct row();
							if($1->isBoolExp==false)$1=int2bool($1);
							if($4->isBoolExp==false)$4=int2bool($4);
							$$->isBoolExp=true;
							backpatch($1->truelist,$3);
							$$->falselist=merge($1->falselist,$4->falselist);
							$$->truelist=$4->truelist;
						}
					  ;

logical_OR_expression:
					 logical_AND_expression{$$=$1;}
					 |logical_OR_expression BINARY_OR M logical_AND_expression
					 	{
					 		$$=new struct row();	
							if($1->isBoolExp==false)$1=int2bool($1);
							if($4->isBoolExp==false)$4=int2bool($4);
							$$->isBoolExp=true;
							backpatch($1->falselist,$3);
							$$->truelist=merge($1->truelist,$4->truelist);
							$$->falselist=$4->falselist;
					 	}
					 ;

conditional_expression:
					  logical_OR_expression{$$=$1;}
					  |logical_OR_expression N QUESTION_MARK M expression N COLON M conditional_expression{}
					  ;

assignment_expression:
					 conditional_expression{$$=$1;}
					 |unary_expression EQUAL assignment_expression
					 	{
					 		/*if($1->isArray==true&&$1->typ_vector.size()>0){quad_array.push_back(quad("[]=",array_name,array_temp_name,$3->Name));}*/
					 		if($1->isArray==true){quad_array.push_back(quad("[]=",array_name,array_temp_name,$3->Name));}
					 		else if($3->isArray==true){quad_array.push_back(quad("=[]",$3->Name,array_name,array_temp_name));
					 		quad_array.push_back(quad($1->Name,$3->Name));}
							else {/*int flag=1;
							if(typecheck($1,$3)!=true){
							if($1->Typ==chartype&&$3->Typ==inttype)$1=char2int($1);
							else if($3->Typ==chartype&&$1->Typ==inttype)$3=char2int($3);
							else if($1->Typ==inttype&&$3->Typ==doubletype)$1=int2doub($1);
							else if($1->Typ==doubletype&&$3->Typ==inttype)$3=int2doub($3);
							else if($1->Typ==doubletype&&$3->Typ==chartype)$3=char2doub($3);
							else if($3->Typ==doubletype&&$1->Typ==chartype)$1=char2doub($1);
							else {flag=0;}
							}
							if(flag==1){*/
							$$=$1;
							quad_array.push_back(quad($1->Name,$3->Name));
							}
						}
					 ;

assignment_expressionopt:
						 assignment_expression{$$=$1;}
						 |{}
						 ;

expression:
		  assignment_expression{$$=$1;}
		  |expression COMMA assignment_expression
		  ;

bool_expression:
				expression{if($1->isBoolExp!=true)$1=int2bool($1);
				$$=$1;}
				;

bool_expressionopt:
					bool_expression{$$=$1;}
					|{}
					;

constant_expression:
				   conditional_expression{$$=$1;}
				   ;

expressionopt:
			  expression
			  |{}
			  ;

declaration:
		   declaration_specifiers init_declarator_list SEMI_COLON
		   	{
		   		$$=$2;
		   	}
		   ;

declaration_specifiers:
					   type_specifier
					   	{	
					   		$$=$1;
					   	}
					  ;

init_declarator_list:
				init_declarator{$$=$1;}
				|init_declarator_list COMMA init_declarator
					{
						$$=$3;
					}
				;

init_declarator:
			   declarator{$$=$1;}
			   |declarator EQUAL initializer
			   	{	
			   		$$=currentST->symbol_table::lookup($1->Name);
			   		$$->init_val=$3->init_val;
			   		quad_array.push_back(quad($$->Name,$3->Name));
			   	}
			   ;

type_specifier:
			  VOID
			  	{
			  		store_type=voidtype;
			  		$$=voidtype;
			  	}
			  |CHAR
			  	{
			  		store_type=chartype;
			  		$$=chartype;
			  	}
			  |INT
			  	{
			  		store_type=inttype;
			  		$$=inttype;
			  	}
			  |DOUBLE
			  	{
			  		store_type=doubletype;
			  		$$=doubletype;
			  	}
			  ;

specifier_qualifier_list:
						type_specifier specifier_qualifier_listopt
							{
								$$=$1;
							}
						;

specifier_qualifier_listopt:
							specifier_qualifier_list
							|
							;

declarator:
		  pointer direct_declarator
		  	{
		  		if($2->Typ==inttype)$2->Typ=ptr_int;
		  		else if($2->Typ==doubletype){$2->Typ=ptr_double;
		  		currentoffset-=4;}
		  		else if($2->Typ==chartype){$2->Typ=ptr_char;
		  		currentoffset+=3;}
		  		$2->size=4;
		  		$$=$2;
		  	}
		  |direct_declarator
		  		{
		  			$$=$1;
		  		}
		  ;

direct_declarator:
				   ID
				   	{	
				   		$$=currentST->lookup(yytext);
				   		$$->offset=currentoffset;
				   		if(store_type==0){$$->Typ=inttype;
				   		$$->size=4;}
				   		if(store_type==1){$$->Typ=doubletype;
				   		$$->size=8;}
				   		if(store_type==2){$$->Typ=chartype;
				   		$$->size=1;}
				   		if(store_type==5){$$->Typ=ptr_int;
				   		$$->size=4;}
				   		if(store_type==6){$$->Typ=ptr_double;
				   		$$->size=4;}
				   		if(store_type==7){$$->Typ=ptr_char;
				   		$$->size=4;}
				   		if(store_type==8){$$->Typ=voidtype;
				   		$$->size=0;}
				   		if(store_type==9){$$->Typ=stringtype;
				   		$$->size=8;}
				   		currentoffset+=$$->size;
				   		$$->isArray=false;
				   	}
				   |LEFT_ROUND_BRACE declarator RIGHT_ROUND_BRACE{}
				   |direct_declarator LEFT_SQUARE_BRACE assignment_expressionopt RIGHT_SQUARE_BRACE
				   	{
				   		currentoffset-=$1->size;
				   		$$=currentST->lookup($1->Name);
				   		int temp=$1->offset;
				   		$1->offset=$3->offset;
				   		$3->offset=temp;
				   		$$->Typ=arraytype;
				   		$$->isArray=true;
				   		if(store_type==0){$$->size=$1->size*atoi($3->init_val.c_str());}
				   		if(store_type==1){$$->size=$1->size*atoi($3->init_val.c_str());}
				   		if(store_type==2){$$->size=$1->size*atoi($3->init_val.c_str());}
				   		currentoffset+=$$->size;
				   		$$->typ_vector.push_back(make_pair(atoi($3->init_val.c_str()),store_type));
				   	}
				   |direct_declarator LEFT_SQUARE_BRACE STATIC assignment_expression RIGHT_SQUARE_BRACE
				   |direct_declarator LEFT_SQUARE_BRACE MULTIPLY RIGHT_SQUARE_BRACE
				   |direct_declarator LEFT_ROUND_BRACE funcdecstart parameter_type_list funcdecend RIGHT_ROUND_BRACE
				   	{	
				   		struct row* temp=$3->lookup("RetVal");
				   		temp->Typ=$1->Typ;
				   		$1->nestedTable=$3;
				   		$1->Typ=functiontype;
				   		func_name=$1->Name;
				   		quad_array.push_back(quad("funcstart",func_name,"0"));
				   	}
				   |direct_declarator LEFT_ROUND_BRACE identifier_listopt RIGHT_ROUND_BRACE
				   ;

funcdecstart:
			{globalST=currentST;
			$$=currentST=new symbol_table();
			globaloffset=currentoffset;
			currentoffset=0;}
			;

funcdecend:
			{currentST=globalST;
			currentoffset=globaloffset;}
			;

pointer:
	   MULTIPLY
	   |MULTIPLY pointer
	   ;

parameter_type_list:
				   parameter_list{}
				   |parameter_list COMMA ELLIPSIS
				   ;

parameter_list:
			  parameter_declaration{currentST->param_count++;}
			  |parameter_list COMMA parameter_declaration{currentST->param_count++;}
			  ;

parameter_declaration:
					 declaration_specifiers declarator
					;

identifier_list:
			   ID
			   |identifier_list COMMA ID
			   ;

identifier_listopt:
				   identifier_list
				   |
				   ;

type_name:
		 specifier_qualifier_list
		 ;

initializer:
		   assignment_expression{$$=$1;}
		   ;

initializer_list:
				designationopt initializer
				|initializer_list COMMA designationopt initializer
				;

designation:
		   designator_list EQUAL
		   ;

designationopt:
		   designation
		   |
		   ;

designator_list:
			   designator 
			   |designator_list designator
			   ;

designator:
		  LEFT_SQUARE_BRACE constant_expression RIGHT_SQUARE_BRACE
		  |PERIOD ID
		  ;

statement:
		  compound_statement{$$=$1;}
		 |expression_statement{$$=$1;}
		 |selection_statement{$$=$1;}
		 |iteration_statement{$$=$1;}
		 |jump_statement{$$=$1;}
		 ;

compound_statement:
				  LEFT_CURLY_BRACE block_item_listopt RIGHT_CURLY_BRACE
				  	{
				  		$$=$2;
				  	}
				  ;

block_item_list:
			   block_item{
			   		$$=$1;
			   		$$->nextlist.clear();
			   	}
			   |block_item_list M block_item{
			   	    $$=$3;
			   		backpatch($1->nextlist,$2);
			   		$$->nextlist=$3->nextlist;
			   	}
			   ;

block_item:
			statement{$$=$1;}
			|declaration{$$=$1;}
			;

block_item_listopt:
				   block_item_list{$$=$1;}
				   |{}
				   ;

expression_statement:
					expressionopt SEMI_COLON{$$=$1;}
					;

selection_statement:
				   IF LEFT_ROUND_BRACE bool_expression RIGHT_ROUND_BRACE M statement N %prec THEN
				   	{
				   		$$=new struct row();
				   		backpatch($7->nextlist,quad_array.size());
				   		backpatch($3->truelist,$5);
						$$->nextlist=merge($3->falselist,$6->nextlist);
				   	}
				   |IF LEFT_ROUND_BRACE bool_expression RIGHT_ROUND_BRACE M statement N ELSE M statement
				   	{
				   		$$=new struct row();
				   		backpatch($3->truelist,$5);
						backpatch($3->falselist,$9);
						$$->nextlist=merge(merge($6->nextlist,$10->nextlist),$7->nextlist);
				   	}
				   ;

iteration_statement:
				   WHILE M LEFT_ROUND_BRACE bool_expression RIGHT_ROUND_BRACE M statement
				   	{
				   		$$=new struct row();
				   		backpatch($7->nextlist,$2);
						backpatch($4->truelist,$6);
						$$->nextlist=$4->falselist;
						quad_array.push_back(quad("goto",$2));
				   	}
				   |DO M statement M WHILE LEFT_ROUND_BRACE bool_expression RIGHT_ROUND_BRACE SEMI_COLON
				   	{
				   		$$=new struct row();
				   		backpatch($7->truelist,$2);
						backpatch($3->nextlist,$4);
						$$->nextlist=$7->falselist;
				   	}
				   |FOR LEFT_ROUND_BRACE expressionopt SEMI_COLON M bool_expressionopt SEMI_COLON M expressionopt N RIGHT_ROUND_BRACE M statement 
				   	{
				   		$$=new struct row();
				   		backpatch($6->truelist,$12);
						backpatch($13->nextlist,$8);
						backpatch($10->nextlist,$5);
						quad_array.push_back(quad("goto",$8));
						$$->nextlist=$6->falselist;
				   	}
				   ;

jump_statement:
			   RETURN expressionopt SEMI_COLON
			   	{
			   		$$=$2;
			   		quad_array.push_back(quad("return",$2->Name,"0"));
			   	}
			  ;

translation_unit:
				external_declaration
				|translation_unit external_declaration
				;

external_declaration:
					function_definition
					|declaration
					;

function_definition:
				    declaration_specifiers declarator compound_statement
				   	{	
				   		quad_array.push_back(quad("funcend",func_name,"0"));
				   		struct row* temp1=currentST->lookup("main");
				   		temp1->Typ=functiontype;
				   	}
				   ;

M:
	{$$=quad_array.size();}
	;
N:
	{
		$$=new struct row();
		$$->nextlist=makelist(quad_array.size());
	 	quad_array.push_back(quad("goto",-1));
	}
	;
%%

void yyerror(char *s) {
    printf("Error occured due to : %s\n",s);
}

row* char2int(row* r)
{
	row* ro;
	ro=symbol_table::gentemp(*currentST);
	ro->isBoolExp=false;
	ro->Typ=inttype;
	ro->init_val=r->init_val;
	ro->size=r->size;
	string s="char2int("+r->Name+")";
	quad_array.push_back(quad(ro->Name,s));
	return ro;
}

row* int2doub(row* r)
{
	row* ro;
	ro=symbol_table::gentemp(*currentST);
	ro->isBoolExp=false;
	ro->Typ=doubletype;
	ro->init_val=r->init_val;
	ro->size=r->size;
	string s="int2doub("+r->Name+")";
	quad_array.push_back(quad(ro->Name,s));
	return ro;
}
row* char2doub(row* r)
{
	row* ro;
	ro=symbol_table::gentemp(*currentST);
	ro->isBoolExp=false;
	ro->Typ=doubletype;
	ro->init_val=r->init_val;
	ro->size=r->size;
	string s="char2doub("+r->Name+")";
	quad_array.push_back(quad(ro->Name,s));
	return ro;
}

row* doub2int(row* r)
{
	row* ro;
	ro=symbol_table::gentemp(*currentST);
	ro->isBoolExp=false;
	ro->Typ=doubletype;
	ro->init_val=r->init_val;
	ro->size=r->size;
	string s="doub2int("+r->Name+")";
	quad_array.push_back(quad(ro->Name,s));
	return ro;
}

row* int2bool(row* r)
{
	row* ro=r;
	if(r->Typ==chartype)ro=char2int(r);
	if(r->Typ==doubletype)ro=doub2int(r);
	ro->isBoolExp=true;
	ro->truelist.push_back(quad_array.size());
	quad_array.push_back(quad("if","...",ro->Name));
	ro->falselist.push_back(quad_array.size());
	quad_array.push_back(quad("goto","...",ro->Name));
	return ro;
}