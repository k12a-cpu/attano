%define api.prefix {attano_yy}

%{

#include <stdint.h>
#include <stdio.h>

#include "lexer_gen.h"
#include "parser.h"

%}

%union{
    uint64_t u64;
    char *str;
    struct {
        uint64_t width;
        uint64_t value;
    } sized_int;
}

%token FATARROW

// Keywords
%token ALIAS
%token BIT
%token BITS
%token COMPOSITE
%token DEVICE
%token FOOTPRINT
%token INSTANCE
%token NODE
%token PIN
%token PRIMITIVE

%token <u64> INT
%token <str> IDENT
%token <str> STRING
%token <sized_int> SIZED_INT

%type <u64> type
%type <u64> expr_list exprs
%type <str> composite_name

%%

compilation_unit
    : items_opt
    ;

items_opt
    : items
    |
    ;

items
    : items item
    | item
    ;

item
    : composite_item
    | atomic_item
    ;

atomic_items_opt
    : atomic_items
    |
    ;

atomic_items
    : atomic_items atomic_item
    | atomic_item
    ;

atomic_item
    : node_item
    | alias_item
    | instance_item
    | primitive_item
    ;

composite_item
    : COMPOSITE composite_name '(' port_list ')'
        { attano_yy_composite_begin($2); }
      '{' atomic_items_opt '}'
        { attano_yy_composite_end(); }
    ;

node_item
    : NODE IDENT ':' type ';'
        { attano_yy_node($2, $4); }
    ;

alias_item
    : ALIAS IDENT '=' expr ';'
        { attano_yy_alias($2); }
    ;

instance_item
    : INSTANCE IDENT ':' composite_name '(' binding_list ')' ';'
        { attano_yy_instance($2, $4); }
    ;

primitive_item
    : PRIMITIVE IDENT '(' primitive_children ')' ';'
        { attano_yy_primitive($2); }
    ;

primitive_children
    : primitive_children primitive_child
    | primitive_child
    ;

primitive_child
    : device_item
    | footprint_item
    | pin_item
    ;

device_item
    : DEVICE STRING ';'             { attano_yy_device($2); }
    ;

footprint_item
    : FOOTPRINT STRING ';'          { attano_yy_footprint($2); }
    ;

pin_item
    : PIN INT FATARROW expr ';'     { attano_yy_pin($2); }
    ;

port_list
    : ports ','
    | ports
    ;

ports
    : ports ',' port
    | port
    ;

port
    : IDENT ':' type                { attano_yy_port($1, $3); }
    ;

binding_list
    : bindings ','
    | bindings
    ;

bindings
    : bindings ',' binding
    | binding
    ;

binding
    : IDENT FATARROW expr           { attano_yy_binding($1); }
    ;

type
    : BIT                           { $$ = 1; }
    | BITS '[' INT ']'              { $$ = $3; }
    ;

expr_list
    : exprs ','                     { $$ = $1; }
    | exprs                         { $$ = $1; }
    ;

exprs
    : exprs ',' expr                { $$ = $1 + 1; }
    | expr                          { $$ = 1; }
    ;

expr
    : expr '[' INT ']'              { attano_yy_expr_slice($3, $3); }
    | expr '[' INT ':' INT ']'      { attano_yy_expr_slice($3, $5); }
    | expr_atom
    ;

expr_atom
    : IDENT                         { attano_yy_expr_noderef($1); }
    | SIZED_INT                     { attano_yy_expr_literal($1.width, $1.value); }
    | '{' expr_list '}'             { attano_yy_expr_concat($2); }
    | '{' INT 'x' expr '}'          { attano_yy_expr_multiply($2); }
    | '(' expr ')'
    ;

composite_name
    : IDENT '[' INT ']'             { char buf[256];
                                      snprintf(buf, 256, "%s[%d]", $1, $3);
                                      $$ = strdup(buf); }
    | IDENT                         { $$ = $1; }
    ;

%%

void attano_parse_stdin() {
    attano_yyin = stdin;
    while (!feof(attano_yyin)) {
        attano_yyparse();
    }
    attano_yyin = NULL;
}

void attano_parse_file(const char *filename) {
    FILE *file = fopen(filename, "r");
    if (file != NULL) {
        attano_yyin = file;
        while (!feof(attano_yyin)) {
            attano_yyparse();
        }
        attano_yyin = NULL;
        fclose(file);
    }
}
