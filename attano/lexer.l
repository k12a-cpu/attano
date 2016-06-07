%option prefix="attano_yy"
%option noyywrap
%option yylineno

%{

#include <stdint.h>
#include <stdlib.h>

#include "parser_gen.h"

%}

%%

[ \t\r\n]               ;
#.*\n                   ;

[\(\)\[\]\{\}=:;,x]     { return attano_yytext[0]; }
=>                      { return FATARROW; }

alias                   { return ALIAS; }
bit                     { return BIT; }
bits                    { return BITS; }
composite               { return COMPOSITE; }
device                  { return DEVICE; }
footprint               { return FOOTPRINT; }
instance                { return INSTANCE; }
node                    { return NODE; }
pin                     { return PIN; }
primitive               { return PRIMITIVE; }

[0-9]+\'b[01]+          { char *endptr;
                          attano_yylval.sized_int.width = (uint64_t) strtol(attano_yytext, &endptr, 10);
                          attano_yylval.sized_int.value = (uint64_t) strtol(endptr + 2, NULL, 2);
                          return SIZED_INT; }

[0-9]+\'d[0-9]+         { char *endptr;
                          attano_yylval.sized_int.width = (uint64_t) strtol(attano_yytext, &endptr, 10);
                          attano_yylval.sized_int.value = (uint64_t) strtol(endptr + 2, NULL, 10);
                          return SIZED_INT; }

[0-9]+\'h[0-9a-fA-F]+   { char *endptr;
                          attano_yylval.sized_int.width = (uint64_t) strtol(attano_yytext, &endptr, 10);
                          attano_yylval.sized_int.value = (uint64_t) strtol(endptr + 2, NULL, 16);
                          return SIZED_INT; }

[0-9]+                  { attano_yylval.u64 = (uint64_t) strtol(attano_yytext, NULL, 10);
                          return INT; }

\"[^"]*\"               { int len = strlen(attano_yytext);
                          attano_yylval.str = strndup(attano_yytext + 1, len - 2);
                          return STRING; }

[a-zA-Z_][a-zA-Z0-9_]*  { attano_yylval.str = strdup(attano_yytext);
                          return IDENT; }

.                       { char msg[24];
                          snprintf(msg, 24, "invalid character '%c'", attano_yytext[0]);
                          attano_yyerror(msg); }

%%
