%{
#include <stdio.h>
#include <stdlib.h>

// Define the tokens.
enum Token {
    LEFT_PARENTHESIS,
    RIGHT_PARENTHESIS,
    SEMICOLON,
    INT,
    ID,
    OP
};

// Define the token structure.
struct LexedToken {
    int token;
    char *lexeme;
    int line;
};

struct LexedToken current_token;

enum CurrentTokenStatus {
    NOT_PRESENT = 0,
    PRESENT = 1,
    WHITESPACE = 2
};

int current_token_status = NOT_PRESENT;

int should_terminate = 0;
%}

%option noyywrap
%option yylineno

ID     [A-Za-z_][A-Za-z_0-9]*
INT    -?[1-9][0-9]*
OP     [-+*/^=]

%%

 /* Print delimiters. */
[(]         {printf("(left-parenthesis %u)\n", yylineno); current_token = {LEFT_PARENTHESIS, "(", yylineno};  current_token_status = PRESENT;}
[)]         {printf("(right-parenthesis %u)\n", yylineno); current_token = {RIGHT_PARENTHESIS, ")", yylineno}; current_token_status = PRESENT;}
[;]         {printf("(semicolon %u)\n", yylineno); current_token = {SEMICOLON, ";", yylineno}; current_token_status = PRESENT;}

 /* Print identifiers, integers and operators. */
[)]         {printf("(right-parenthesis %u)\n", yylineno); current_token = {RIGHT_PARENTHESIS, ")", yylineno}; current_token_status = PRESENT;}
[;]         {printf("(semicolon %u)\n", yylineno); current_token = {SEMICOLON, ";", yylineno}; current_token_status = PRESENT;}

 /* Print identifiers, integers and operators. */
{INT}       {printf("(int %s %u)\n",yytext, yylineno); current_token = {INT, yytext, yylineno}; current_token_status = PRESENT;}
{ID}        {printf("(id \"%s\" %u)\n", yytext, yylineno); current_token = {ID, yytext, yylineno}; current_token_status = PRESENT;}
{OP}        {printf("(op \"%s\" %u)\n", yytext, yylineno); current_token = {OP, yytext, yylineno}; current_token_status = PRESENT;}

 /* Ignore comments and whitespace. */
#[^\n]*     {current_token_status = WHITESPACE;}
[ \t\r\n]   {current_token_status = WHITESPACE;}

<<EOF>>     {printf("(eof %u)\n", yylineno); return 0;}
%%


