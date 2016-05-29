#!/bin/sh

flex --header-file=attano/lexer_gen.h --outfile=attano/lexer_gen.c attano/lexer.l
bison --defines=attano/parser_gen.h --output=attano/parser_gen.c attano/parser.y
