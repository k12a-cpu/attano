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
%token CREATE
%token DEVICE
%token FOOTPRINT
%token NODE
%token PIN
%token PRIMITIVE

%token <u64> INT
%token <str> IDENT
%token <str> STRING
%token <sized_int> SIZED_INT

%type <u64> type
%type <u64> expr_list exprs
%type <str> component_name instance_name node_name

%%

compilation_unit
    : items
    ;

items
    : items item
    | item
    ;

item
    : primitive_item
    | composite_item
    | create_item
    | node_item
    | alias_item
    ;

primitive_item
    : PRIMITIVE component_name '(' port_list ')' '{'
        { attano_yy_begin_primitive($2); }
      primitive_children '}'
        { attano_yy_end_primitive(); }
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
    : DEVICE STRING ';'
        { attano_yy_set_device($2); }
    ;

footprint_item
    : FOOTPRINT STRING ';'
        { attano_yy_set_footprint($2); }
    ;

pin_item
    : PIN INT FATARROW expr ';'
        { attano_yy_add_pin_mapping($2); }
    ;

composite_item
    : COMPOSITE component_name '(' port_list ')' '{'
        { attano_yy_begin_composite($2); }
      composite_children '}'
        { attano_yy_end_composite(); }
    ;

composite_children
    : composite_children composite_child
    | composite_child
    ;

composite_child
    : create_item
    | node_item
    ;

create_item
    : CREATE instance_name ':' component_name '(' binding_list ')' ';'
        { attano_yy_construct_instance($2, $4); }
    ;

node_item
    : NODE node_name ':' type ';'
        { attano_yy_construct_node($2, $4); }
    ;

alias_item
    : ALIAS node_name '=' expr ';'
        { attano_yy_construct_alias($2); }
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
    : node_name ':' type            { attano_yy_construct_port($1, $3); }
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
    : node_name FATARROW expr       { attano_yy_construct_binding($1); }
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
    : expr '[' INT ']'              { attano_yy_construct_expr_slice($3, $3); }
    | expr '[' INT ':' INT ']'      { attano_yy_construct_expr_slice($3, $5); }
    | expr_atom
    ;

expr_atom
    : node_name                     { attano_yy_construct_expr_noderef($1); }
    | SIZED_INT                     { attano_yy_construct_expr_literal($1.width, $1.value); }
    | '{' expr_list '}'             { attano_yy_construct_expr_concat($2); }
    | '{' INT 'x' expr '}'          { attano_yy_construct_expr_multiply($2); }
    | '(' expr ')'
    ;

component_name
    : IDENT '[' INT ']'             { char buf[256];
                                      snprintf(buf, 256, "%s[%d]", $1, $3);
                                      $$ = strdup(buf); }
    | IDENT                         { $$ = $1; }
    ;

instance_name
    : IDENT                         { $$ = $1; }
    ;

node_name
    : IDENT                         { $$ = $1; }
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
