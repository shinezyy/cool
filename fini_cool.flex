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

#define ADDSTRING do{cool_yylval.symbol = stringtable.add_string(yytext);} while(0)
#define ADDID do{cool_yylval.symbol = idtable.add_string(yytext);} while(0)
#define ADDINT do{cool_yylval.symbol = inttable.add_string(yytext);} while(0)
#define ADDCURRENTS do{cool_yylval.symbol = inttable.add_string(currents);} while(0)

// for comments
int commlevel = 0;

// for string
char *currents;
uint currentlen = 0;
uint currentsize = 0;
uint maxlen = 1024;
bool toolong = false;
void appendcurrents(char *);
void appendchar(char);
void cleans();
%}

/*
 * Define names for regular expressions here.
 */

DARROW          =>
LE              <=
ASSIGN          <-

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

D       [0-9]
W       [A-Za-z]
DW      [0-9A-Za-z]
SPACE   [\x20\r\t\v]

%START comm 
%START instring 
%START sescape
%START stringerror

%%
<INITIAL,comm>\n              { curr_lineno++; }
<INITIAL,instring,comm>{SPACE}+           { ; }

 /*
  *  Nested comments
  */

<INITIAL>"(*"           { BEGIN comm; commlevel = 1; }
<comm>\(                { ; }
<comm>"(*"              { commlevel++; }
<comm>[^\*\n\(]*        { ; }
<comm>\\.               { ; }
<comm>\*                { ; }
<comm>"*)"              {
                        commlevel--; 
                        if (commlevel == 0) {
                            BEGIN 0; 
                        }
                        }
<comm><<EOF>>           {
                        BEGIN stringerror;
                        cool_yylval.error_msg = "EOF in string comment";
                        return(ERROR);
                        }


<INITIAL>\-\-[^\n]*     { ; }
<INITIAL>"*)"           {
                        cool_yylval.error_msg = "Unmatched *)";
                        return (ERROR);
                        }
<INITIAL>[\!\0\#\$\%\^\&\_\>\?\`\[\]\\\|]         {
                        cool_yylval.error_msg = yytext;
                        return(ERROR);
                        }
<INITIAL>[\<\>\~\.\{\}\:\;\(\)\,\+\-\*\=\/\@\~]  { return *(yytext); }
<INITIAL>[\1\2\3\4] {
                cool_yylval.error_msg = yytext;
                return(ERROR);
                }

<instring>\n    {
                BEGIN 0;
                curr_lineno++; cleans(); 
                cool_yylval.error_msg = "Unterminated string constant";
                return(ERROR); 
                }
<instring>\"    { 
                BEGIN 0; 
                if (currentlen == 0) {
                    cool_yylval.symbol = inttable.add_string("");
                } else {
                    ADDCURRENTS; cleans();
                }
                toolong = false;
                return (STR_CONST); 
                }
<instring>\\    { BEGIN sescape; }
<sescape>b      { appendchar('\b');
                if (toolong) {
                    BEGIN stringerror;
                    cool_yylval.error_msg = "String constant too long";
                    return(ERROR);
                } else { BEGIN instring; }
                }
<sescape>t      { appendchar('\t'); 
                if (toolong) {
                    BEGIN stringerror;
                    cool_yylval.error_msg = "String constant too long";
                    return(ERROR);
                } else {BEGIN instring; }
                }
<sescape>n      { appendchar('\n');
                if (toolong) {
                    BEGIN stringerror;
                    cool_yylval.error_msg = "String constant too long";
                    return(ERROR);
                } else { BEGIN instring; }
                }
<sescape>f      { appendchar('\f');
                if (toolong) {
                    BEGIN stringerror;
                    cool_yylval.error_msg = "String constant too long";
                    return(ERROR);
                } else { BEGIN instring; }
                }
<sescape>\n     { appendchar('\n'); 
                if (toolong) {
                    BEGIN stringerror;
                    cool_yylval.error_msg = "String constant too long";
                    return(ERROR);
                } else { BEGIN instring;}
                curr_lineno++; 
                }
<instring,sescape,comm>\0      {
                BEGIN stringerror;
                cool_yylval.error_msg = "String contains null character.";
                return(ERROR); }
<sescape>\0     {
                BEGIN stringerror;
                cool_yylval.error_msg = "String contains escaped null character.";
                return(ERROR); }
<sescape>.      { 
                appendcurrents(yytext);
                if (toolong) {
                    BEGIN stringerror;
                    cool_yylval.error_msg = "String constant too long";
                    return(ERROR);
                } else {
                    BEGIN instring;
                }
                }

<instring,sescape><<EOF>>   { 
                BEGIN stringerror; 
                cool_yylval.error_msg = "EOF in string constant";
                return(ERROR); }
<instring>[^\n\\\"\0]*  { 
                appendcurrents(yytext);
                if (toolong) {
                    BEGIN stringerror;
                    cool_yylval.error_msg = "String constant too long";
                    return(ERROR);
                } 
                }
<stringerror>[^\n\"]*   { ; }
<stringerror>\n         { curr_lineno++; BEGIN 0; }
<stringerror>\"         { BEGIN 0; toolong = false; }
                        
<INITIAL>\"             { BEGIN instring; }


 /*
  *  The multiple-character operators.
  */

<INITIAL>{DARROW}     { return (DARROW); }
<INITIAL>{ASSIGN}       { return (ASSIGN); }
<INITIAL>{LE}           { return (LE); }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */

<INITIAL>{c}{l}{a}{s}{s}           { return (CLASS); }
<INITIAL>{e}{l}{s}{e}            { return (ELSE); }
<INITIAL>f{a}{l}{s}{e}           { cool_yylval.boolean = 0; return (BOOL_CONST); }
<INITIAL>{f}{i}              { return (FI); }
<INITIAL>{i}{f}              { return (IF); }
<INITIAL>{i}{n}              { return (IN); }
<INITIAL>{i}{n}{h}{e}{r}{i}{t}{s}        { return (INHERITS); }
<INITIAL>{i}{s}{v}{o}{i}{d}          { return (ISVOID); }
<INITIAL>{l}{e}{t}             { return (LET); }
<INITIAL>{l}{o}{o}{p}            { return (LOOP); }
<INITIAL>{p}{o}{o}{l}            { return (POOL); }
<INITIAL>{t}{h}{e}{n}            { return (THEN); }
<INITIAL>{w}{h}{i}{l}{e}           { return (WHILE); }
<INITIAL>{c}{a}{s}{e}            { return (CASE); }
<INITIAL>{e}{s}{a}{c}            { return (ESAC); }
<INITIAL>{n}{e}{w}             { return (NEW); }
<INITIAL>{o}{f}              { return (OF); }
<INITIAL>{n}{o}{t}             { return (NOT); }
<INITIAL>t{r}{u}{e}            { cool_yylval.boolean = 1; return (BOOL_CONST); }

 /*
  * my identifiers
  */

 /*
  * my integers
  */
<INITIAL>{D}+   {
                ADDINT;
                return(INT_CONST);
                }
<INITIAL>[A-Z]({DW}|_)*  {
                ADDID;
                return(TYPEID);
                }

<INITIAL>[a-z]({DW}|_)*  {
                ADDID;
                return(OBJECTID);
                }
<INITIAL>\_     {
                cool_yylval.error_msg = yytext;
                return (ERROR);
                }
<INITIAL>.      { ; }
 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */


%%
void appendcurrents(char *s) {
    if (currentlen + strlen(s) > maxlen) {
        toolong = true;
        cleans();
        return;
    }
    if (currentlen + strlen(s) < currentsize) {
        strcat(currents, s); 
    } else {
        char *old = currents;
        while (currentlen + strlen(s) >= currentsize)
            currentsize += 16;
        currents = (char*)malloc(currentsize * sizeof(char));
        currents[0] = '\0';
        if (currentlen > 0) {
            strcpy(currents, old);
            free((void*)old);
        }   
        strcat(currents, s); 
    }   
    currentlen += strlen(s);
}

void appendchar(char c) {
    char s[] = {"a"};
    s[0] = c;
    appendcurrents(s);
}
void cleans() {
    if (currentlen > 0) {
        free(currents);
        currentlen = 0;
        currentsize = 0;
    }
}
