/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */
int comment_nest=0;

%}

/*
 * Define names for regular expressions here.
 */

a       [aA]
b       [bB]
c       [cC]
d       [dD]
e       [eE]
f       [fF]
g       [gG]
h       [hH]
i       [iI]
j       [jJ]
k       [kK]
l       [lL]
m       [mM]
n       [nN]
o       [oO]
p       [pP]
q       [qQ]
r       [rR]
s       [sS]
t       [tT]
u       [uU]
v       [vV]
w       [wW]
x       [xX]
y       [yY]
z       [zZ]

num		[0-9]
alpha	[a-zA-Z]
alnum	[0-9a-zA-Z]

DARROW          =>
ASSIGN			<-
LE				<=

%START comment
%START string

%%

 /*
  * line number inc
  */
<INITIAL>\n			{curr_lineno++;}
<comment>\n			{curr_lineno++;}

 /*
  *   comments
  */
<INITIAL>\-\-[^\n]	{;}
<INITIAL>"(*"		{comment_nest=1;BEGIN comment;}
<comment>"(*"		{comment_nest++;}
<comment>[^\*\(\n]* { ; }
<comment>"*)"		{comment_nest--;if(comment_nest==0)BEGIN INITIAL;}
<comment><<EOF>>	{BEGIN INITIAL;cool_yylval.error_msg = "comments met EOF"; return (ERROR);}

<INITIAL>\"			{BEGIN string;}
<string>\"			{BEGIN INITIAL;}
<string>[^\"]+		{cool_yylval.symbol = stringtable.add_string(yytext);
					return (STR_CONST);}

 /*
  *  The multiple-character operators.
  */
<INITIAL>{DARROW}		{return (DARROW);}
<INITIAL>{ASSIGN}		{return (ASSIGN);}
<INITIAL>{LE}			{return (LE); }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
<INITIAL>{c}{l}{a}{s}{s}			{return (CLASS);}
<INITIAL>{i}{n}{h}{e}{r}{i}{t}{s}	{return (INHERITS);}

<INITIAL>{i}{f}						{return (IF);}
<INITIAL>{t}{h}{e}{n}				{return (THEN);}
<INITIAL>{e}{l}{s}{e}				{return (ELSE);}
<INITIAL>{f}{i}						{return (FI);}

<INITIAL>{w}{h}{i}{l}{e}			{return (WHILE);}
<INITIAL>{l}{o}{o}{p}				{return (LOOP);}
<INITIAL>{p}{o}{o}{l}				{return (POOL);}

<INITIAL>{c}{a}{s}{e}				{return (CASE);}
<INITIAL>{o}{f}						{return (OF);}
<INITIAL>{e}{s}{a}{c}				{return (ESAC);}

<INITIAL>{l}{e}{t}					{return (LET);}
<INITIAL>{n}{e}{w}					{return (NEW);}
<INITIAL>{n}{o}{t}					{return (NOT);}

<INITIAL>t{r}{u}{e}					{cool_yylval.boolean = 0;return BOOL_CONST;}
<INITIAL>f{a}{l}{s}{e}				{cool_yylval.boolean = 1;return BOOL_CONST;}

<INITIAL>{i}{s}{v}{o}{i}{d}			{return (ISVOID);}
<INITIAL>{i}{n}						{return (IN);}

 /*
  *single-char operators
  */

<INITIAL>[\+\-\*\/\~\<\=\(\)\{\}\.\;\:\,\@]				{ return *(yytext); }
<INITIAL>[\ \n\t\b\f]				{;}

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */
<INITIAL>[A-Z]({alnum}|_)* {
	cool_yylval.symbol = idtable.add_string(yytext);
	return (TYPEID);
}
<INITIAL>[a-z]({alnum}|_)* {
	cool_yylval.symbol = idtable.add_string(yytext);
	return (OBJECTID);
}
<INITIAL>({num})+ {
	cool_yylval.symbol = inttable.add_string(yytext);
	return (INT_CONST);
}

<INITIAL>[^\+\-\*\/\~\<\=\(\)\{\}\.\;\:\,\@0-9a-zA-Z]		{
														  cool_yylval.error_msg = yytext;
														  return (ERROR); 
														}



%%
