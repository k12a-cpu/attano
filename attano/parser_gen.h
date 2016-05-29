/* A Bison parser, made by GNU Bison 3.0.4.  */

/* Bison interface for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015 Free Software Foundation, Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

#ifndef YY_ATTANO_YY_ATTANO_PARSER_GEN_H_INCLUDED
# define YY_ATTANO_YY_ATTANO_PARSER_GEN_H_INCLUDED
/* Debug traces.  */
#ifndef ATTANO_YYDEBUG
# if defined YYDEBUG
#if YYDEBUG
#   define ATTANO_YYDEBUG 1
#  else
#   define ATTANO_YYDEBUG 0
#  endif
# else /* ! defined YYDEBUG */
#  define ATTANO_YYDEBUG 0
# endif /* ! defined YYDEBUG */
#endif  /* ! defined ATTANO_YYDEBUG */
#if ATTANO_YYDEBUG
extern int attano_yydebug;
#endif

/* Token type.  */
#ifndef ATTANO_YYTOKENTYPE
# define ATTANO_YYTOKENTYPE
  enum attano_yytokentype
  {
    FATARROW = 258,
    ALIAS = 259,
    BIT = 260,
    BITS = 261,
    COMPOSITE = 262,
    CREATE = 263,
    DEVICE = 264,
    FOOTPRINT = 265,
    NODE = 266,
    PIN = 267,
    PRIMITIVE = 268,
    INT = 269,
    IDENT = 270,
    STRING = 271,
    SIZED_INT = 272
  };
#endif

/* Value type.  */
#if ! defined ATTANO_YYSTYPE && ! defined ATTANO_YYSTYPE_IS_DECLARED

union ATTANO_YYSTYPE
{
#line 13 "attano/parser.y" /* yacc.c:1909  */

    uint64_t u64;
    char *str;
    struct {
        uint64_t width;
        uint64_t value;
    } sized_int;

#line 89 "attano/parser_gen.h" /* yacc.c:1909  */
};

typedef union ATTANO_YYSTYPE ATTANO_YYSTYPE;
# define ATTANO_YYSTYPE_IS_TRIVIAL 1
# define ATTANO_YYSTYPE_IS_DECLARED 1
#endif


extern ATTANO_YYSTYPE attano_yylval;

int attano_yyparse (void);

#endif /* !YY_ATTANO_YY_ATTANO_PARSER_GEN_H_INCLUDED  */
