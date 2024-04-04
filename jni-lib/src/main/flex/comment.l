%{
#include <stdio.h>
#include <stdlib.h>

unsigned int code = 0 ; /* Bytes of code. */
unsigned int comm = 0 ; /* Bytes of comments. */



// Define the tokens.
enum Token {
    COMMENT = 0,
    CODE = 1,
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
};

int current_token_status = NOT_PRESENT;

#define VALUE {strdup(yytext)}
#define CODE {return 1;}
#define COMM {return 2;}

%}

%option noyywrap
%option yylineno

%x INCOMMENT INSTRING

%%

 /* Switch to comments on '/*' */
<INITIAL>"/*"      { COMM ; BEGIN(INCOMMENT) ; }
<INCOMMENT>"*/"    { COMM ; BEGIN(INITIAL) ; }
<INCOMMENT>.|\n    { COMM ; }

 /* Switch to string mode on '"' */
<INITIAL>\"      { CODE ; BEGIN(INSTRING) ; }
<INSTRING>\\\"   { CODE ; } /* Escaped quote. */
<INSTRING>\"     { CODE ; BEGIN(INITIAL) ; }
<INSTRING>.|\n   { CODE ; }

<INITIAL>['](\\)?\"['] { CODE ; } /* Character quote. */
<INITIAL>.|\n          { CODE ; }

<<EOF>>   {printf("EOF") ;return 0 ; }

%%