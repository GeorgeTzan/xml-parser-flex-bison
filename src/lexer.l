%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h"

%}

%option noyywrap
%option yylineno
%option nounput
%option noinput

%%

[ \t]+                  { /* skip whitespace */ }
[\n]                    { yylineno++; }

"<!--"[^-]*("-"+[^-][^-]*)*"-"*"-->" { /* skip comments */ }
"<?xml"[^?]*"?>"       { /* skip XML declaration */ }

"<LinearLayout"        { return LTAG; }
"<RelativeLayout"      { return RTAG; }
"<TextView"            { return TVTAG; }
"<ImageView"           { return IVTAG; }
"<Button"              { return BTAG; }
"<RadioGroup"          { return RGTAG; }
"<RadioButton"         { return RBTAG; }
"<ProgressBar"         { return PBTAG; }

"</LinearLayout>"      { return LCLOSE; }
"</RelativeLayout>"    { return RCLOSE; }
"</RadioGroup>"        { return RGCLOSE; }

"/>"                   { return SELFCLOSE; }
">"                    { return GT; }

"android:layout_width"  { return AWIDTH; }
"android:layout_height" { return AHEIGHT; }
"android:id"            { return AID; }
"android:text"          { return ATEXT; }
"android:src"           { return ASRC; }
"android:padding"       { return APADDING; }
"android:textColor"     { return ACOLOR; }
"android:max"           { return AMAX; }
"android:progress"      { return APROGRESS; }
"android:checkedButton" { return ACHECKED; }
"android:orientation"   { return AORIENT; }
"android:radioButtonCount" { return ACOUNT; }

"="                    { return EQ; }

\"[^\"]*\"             { yylval.str = yytext; return VALUE; }
[0-9]+                 { yylval.num = atoi(yytext); return NUM; }

.                      { /* ignore */ }

<<EOF>>               { return 0; }

%%
