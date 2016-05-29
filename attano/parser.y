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
    : PRIMITIVE component_name '(' port_list ')' '{' primitive_children '}'
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
    ;

footprint_item
    : FOOTPRINT STRING ';'
    ;

pin_item
    : PIN INT FATARROW expr ';'
    ;

composite_item
    : COMPOSITE component_name '(' port_list ')' '{' composite_children '}'
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
    ;

node_item
    : NODE node_name ':' type ';'
    ;

alias_item
    : ALIAS node_name '=' expr ';'
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
    : node_name ':' type
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
    : node_name FATARROW expr
    ;

type
    : BIT
    | BITS '[' INT ']'
    ;

expr_list
    : exprs ','
    | exprs
    ;

exprs
    : exprs ',' expr
    | expr
    ;

expr
    : expr '[' INT ']'
    | expr '[' INT ':' INT ']'
    | expr_atom
    ;

expr_atom
    : node_name
    | SIZED_INT
    | '{' expr_list '}'
    | '{' INT 'x' expr_atom '}'
    | '(' expr ')'
    ;

component_name
    : IDENT '[' INT ']'
    | IDENT
    ;

instance_name
    : IDENT
    ;

node_name
    : IDENT
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
