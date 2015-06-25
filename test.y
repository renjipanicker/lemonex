%include {
#include <assert.h>
#include <stdlib.h>
#include <string.h>

int expd = 0;
int pres = 0;
int fres = 0;

int acc = 0;
int err = 0;

#define TSTP(s) { \
  ++expd; \
  acc = 0; \
  err = 0; \
  int rc = ParseReadString(s, "", "TEST:"); \
  if((rc != 0) || (acc == 0) || (err != 0)) { \
    printf("FAIL[%s]:%d,%d,%d\n", s, rc, acc, err); \
    ++fres; \
    return 1; \
  } \
  ++pres; \
  printf("PASS[%s]\n", s); \
}

#define TSTF(s) { \
  ++expd; \
  acc = 0; \
  err = 0; \
  int rc = ParseReadString(s, "", "TEST:"); \
  if((acc != 0) || (err == 0)) { \
    printf("FAIL[%s]:%d,%d,%d\n", s, rc, acc, err); \
    ++fres; \
    return 1; \
  } \
  ++pres; \
  printf("PASS[%s]\n", s); \
}

static int check(const char* t, const char *s) {
  if(strcmp(t, s) != 0){
    return 0;
  }
  return 1;
}

static int leave(){
  if(pres != expd){
    printf("FAIL:exp:%d, cnt:%d\n", expd, pres);
    exit(1);
  }
  return 0;
}

#define ISEQ(T, S) check(T.buf, S)
#define VERIFY(c) assert(c)

}

%parse_accept {
#if LEMONEX_DBG>=1
  printf("parsing complete!\n");
#endif
  acc = 1;
}

%syntax_error {
  printf("syntax_error\n");
  err = 1;
}

%start_symbol rModule

/*****************************************
All test cases must be prefixed as follows:
# S_XXX = expect Success
# G_XXX = expect Generation error
# C_XXX = expect Compilation error
# R_XXX = expect Runtime error

todo: test case for overlapping captures
todo: test case for ranges
todo: test case for * and + overlap
*/

/******************************************/
%ifdef S_BTST01
rModule ::= EX1(E1) EX2(E2). {VERIFY((ISEQ(E1, "AB")||ISEQ(E1, "B")) && (ISEQ(E2, "AC")||ISEQ(E2, "C")));}
EX1 ::= "A*B".
EX2 ::= "A*C".
WS ::= " ".
%code {
  int main(int argc, char* argv[]) {
    TSTP("AB AC");
    TSTP("B AC");
    TSTP("AB C");
    TSTP("B C");
    return leave();
  }
}
%endif

/******************************************/
%ifdef G_BTST02
rModule ::= EX1(E1) EX2(E2). {VERIFY(ISEQ(E1, "AB") && ISEQ(E2, "AC"));}
EX1 ::= "AB*".
EX2 ::= "AC*".
WS ::= " ".
%code {
  int main(int argc, char* argv[]) {
    TSTP("AB AC");
    return leave();
  }
}
%endif

/******************************************/
%ifdef S_BTST03
rModule ::= EX1(E1) EX2(E2). {VERIFY((ISEQ(E1, "ABD")||ISEQ(E1, "B")) && (ISEQ(E2, "ACE")||ISEQ(E2, "C")));}
EX1 ::= "AB*D".
EX2 ::= "AC*E".
WS ::= " ".
%code {
  int main(int argc, char* argv[]) {
    TSTP("ABD ACE");
    TSTF("ABE ACE");
    TSTF("ABD ACD");
    return leave();
  }
}
%endif

/******************************************/
%ifdef S_BTST04
rModule ::= EX1(E1) EX2(E2). {VERIFY((ISEQ(E1, "ABD")||ISEQ(E1, "B")) && (ISEQ(E2, "ACD")||ISEQ(E2, "C")));}
EX1 ::= "AB*D".
EX2 ::= "AC*D".
WS ::= " ".
%code {
  int main(int argc, char* argv[]) {
    TSTP("ABD ACD");
    TSTF("ABE ACE");
    TSTF("AD AD");
    return leave();
  }
}
%endif

/******************************************/
%ifdef S_BTST05
rModule ::= EX1(E1) EX2(E2). {VERIFY((ISEQ(E1, "AD")||ISEQ(E1, "AAD")) && (ISEQ(E2, "CD")||ISEQ(E2, "CCD")));}
EX1 ::= "A*D".
EX2 ::= "C*D".
WS ::= " ".
%code {
  int main(int argc, char* argv[]) {
    TSTP("AD CD");
    TSTP("AAD CCD");
    TSTF("D D");
    return leave();
  }
}
%endif

/******************************************/
%ifdef S_BTST06
rModule ::= EX1(E1). {VERIFY(ISEQ(E1, "A")||ISEQ(E1, "AA")||ISEQ(E1, ""));}
EX1 ::= "A*".
WS ::= " ".
%code {
  int main(int argc, char* argv[]) {
    TSTP("A");
    TSTP("AA");
    TSTP("");
    return leave();
  }
}
%endif

/******************************************/
%ifdef S_BTST07
rModule ::= EX1(E1) EX2(E2). {VERIFY((ISEQ(E1, "ABM")||ISEQ(E1, "B")) && (ISEQ(E2, "ACD")||ISEQ(E2, "C")));}
EX1 ::= "A[B-K]M".
EX2 ::= "ACD".
WS ::= " ".
%code {
  int main(int argc, char* argv[]) {
    TSTP("ABM ACD");
    TSTF("ABM ABD");
    return leave();
  }
}
%endif

/******************************************/
%ifdef S_BTST08
rModule ::= EX1(E1) EX2(E2). {VERIFY((ISEQ(E1, "ABM")||ISEQ(E1, "B")) && (ISEQ(E2, "AEH")||ISEQ(E2, "C")));}
EX1 ::= "A[B-K]M".
EX2 ::= "A[D-G]H".
WS ::= " ".
%code {
  int main(int argc, char* argv[]) {
    TSTP("ABM AEH");
    TSTF("ABM ABD");
    return leave();
  }
}
%endif

/******************************************/
%ifdef S_BTST09
rModule ::= EX1(E1) EX2(E2) EX3(E3). {VERIFY((ISEQ(E1, "ABM")||ISEQ(E1, "B")) && (ISEQ(E2, "AEH")||ISEQ(E2, "C")) && (ISEQ(E3, "ADI")||ISEQ(E3, "C")));}
EX1 ::= "A[B-K]M".
EX2 ::= "A[E-F]H".
EX3 ::= "A[D-G]I".
WS ::= " ".
%code {
  int main(int argc, char* argv[]) {
    TSTP("ABM AEH ADI");
    TSTF("ABM ABD");
    return leave();
  }
}
%endif

/******************************************/
%ifdef S_TST01
rModule ::= rWordList EOL.

rWordList ::= rWordList rWord.
rWordList ::= rWord.

rWord ::= WORD.
rWord ::= CREATE(T). {assert(strcmp(T.buf, "CREATE") == 0);}
rWord ::= CLOSE(T). {assert(strcmp(T.buf, "CLOSE") == 0);}
rWord ::= TPLUS(T). {assert((strcmp(T.buf, "PLXUS") == 0) || (strcmp(T.buf, "PLAUS") == 0) || (strcmp(T.buf, "PLYUS") == 0));}
rWord ::= ATTACH(T). {assert(strcmp(T.buf, "ATTACH") == 0);}
rWord ::= FSTAR.
rWord ::= FRAGMENT.
rWord ::= SQUOTE.
rWord ::= VARNAME.
rWord ::= ABC(T). {assert(strcmp(T.buf, "ABC") == 0);}

ENTER_METAMODE ::= "<{{". [METAMODE]
EOL ::= "|".

%lexer_mode METAMODE.
LEAVE_METAMODE ::= "}}>". [<]

CREATE ::= "CREATE".
WORD ::= "CC*EATE".

WORD ::= "CC*OSE".
WORD ::= "D*ASE".
ABC ::= "ABC".
ATTACH ::= "AT(T|Y)AC*H".
WORD ::= "[\l][\l\d_]*".
CLOSE ::= "CLOSE".
WORD ::= "[\d]+".

WORD ::= "\".*\"".
TPLUS ::= "PL.US".
VARNAME ::= !"@" "[\l][\l\d_]*".
FSTAR ::= !"{" "@[\l][\l\d_]*" !"}".
FSTAR ::= !"{" "@[\l][\l\d_]*:@[\l][\l\d_]*" !"}".

WS ::= " ".
EOL ::= "|".

%code {
  int main(int argc, char* argv[]) {
    TSTP("<{{1234}}>|");
    TSTP("<{{A ABCDEF \"GHIJKL\" PLAUS MNOP}}>|");
    TSTP("<{{ABCDEF PLAUS MNOP}}>|");
    TSTP("<{{ CREATE CLOSE ATTACH}}>|");
    TSTP("<{{\"ABC\"}}>|");
    TSTP("<{{CREATE CEATE CCEATE CCCEATE CCCCEATE EATE OSE ASE}}>|");
    TSTP("<{{CEATE CCEATE CCCEATE CCCCEATE}}>|");
    TSTP("<{{ABC}}>|");
    TSTP("<{{EATE}}>|");
    TSTP("<{{PLXUS PLYUS}}>|");
    TSTP("<{{CCABC}}>|");
    TSTP("<{{ABC {@d} @e DEF}}>|");
    return leave();
  }
}
%endif

/******************************************/
%ifdef S_TST02
rModule ::= WORD(W) EOL. {VERIFY(ISEQ(W, "ABCED") || ISEQ(W, "A") || ISEQ(W, "AB") || ISEQ(W, "ABC"));}
EOL  ::= "[,]".
WORD ::= "[\l\d][^,]*".

%code {
  int main(int argc, char* argv[]) {
    TSTP("ABCED,");
    TSTP("A,");
    TSTP("AB,");
    TSTP("ABC,");
    return leave();
  }
}
%endif

/******************************************/
%ifdef S_TST03
rModule ::= WORD(W) EOL. {VERIFY(ISEQ(W, "ABCED") || ISEQ(W, "A") || ISEQ(W, "AB") || ISEQ(W, "ABC"));}
EOL  ::= "[,]".
WORD ::= ".+".

%code {
  int main(int argc, char* argv[]) {
    TSTP("ABCED,");
    TSTP("A,");
    TSTP("AB,");
    TSTP("ABC,");
    return leave();
  }
}
%endif

/******************************************/
%ifdef G_TST04
rModule ::= WORD EOL.
WORD ::= "[\l][^XBZ]Y".
WORD ::= "[\l][^AYC]!".

%code {
  int main(int argc, char* argv[]) {
    TSTP("ASY|");
    return leave();
  }
}
%endif

/******************************************/
%ifdef S_TST05
rModule ::= WORD(W) EOL. {VERIFY(ISEQ(W, "ABCED") || ISEQ(W, "A") || ISEQ(W, "AB") || ISEQ(W, "ABC"));}
EOL  ::= "[,]".
WORD ::= "..*".

%code {
  int main(int argc, char* argv[]) {
    TSTP("ABCED,");
    TSTP("A,");
    TSTP("AB,");
    TSTP("ABC,");
    return leave();
  }
}
%endif

/******************************************/
%ifdef S_TST06
rModule ::= TEXT(W) EOL. {VERIFY(ISEQ(W, "ABCED") || ISEQ(W, "A") || ISEQ(W, "AB") || ISEQ(W, "ABC"));}
EOL ::= "|".
TEXT ::= "[\l][\l\d]*".

%code {
  int main(int argc, char* argv[]) {
    TSTP("ABCED|");
    TSTP("A|");
    TSTP("AB|");
    TSTP("ABC|");
    return leave();
  }
}
%endif

/******************************************/
%ifdef S_TST07
rModule ::= TEXT(W) EOL. {VERIFY(ISEQ(W, "ABCED"));}
EOL ::= "[\.\!\?]".
TEXT ::= "[\l\d][^\.\!\?]*".

%code {
  int main(int argc, char* argv[]) {
    TSTP("ABCED.");
    return leave();
  }
}
%endif

/******************************************/
%ifdef S_TST08
rModule ::= TEXT(W) EOL(E). {VERIFY(ISEQ(W, "DA") && ISEQ(E, "AD"));}
EOL  ::= "[ABC]D".
TEXT ::= "[^ABC]A".
WS ::= " ".

%code {
  int main(int argc, char* argv[]) {
    TSTP("DA AD");
    return leave();
  }
}
%endif

/******************************************/
%ifdef S_TST09
rModule ::= TEXT(W) EOL(E). {VERIFY((ISEQ(W, "DA") || ISEQ(W, "QETA")) && ISEQ(E, "AD"));}
EOL  ::= "[ABC]D".
TEXT ::= "([^ABCE ](E|A))+".
WS ::= " ".

%code {
  int main(int argc, char* argv[]) {
    TSTP("DA AD");
    TSTF("EA AD");
    TSTP("QETA AD");
    return leave();
  }
}
%endif

/******************************************/
%ifdef S_TST10
rModule ::= TEXT(W) EOL(E). {VERIFY(ISEQ(W, "DA") && ISEQ(E, "A"));}
EOL  ::= "[ABC]".
TEXT ::= "([^ABCE ](E|A))+".
WS ::= " ".

%code {
  int main(int argc, char* argv[]) {
    TSTP("DA A");
    TSTF("EA A");
    return leave();
  }
}
%endif

/******************************************/
%ifdef S_TST11
rModule ::= TEXT(V) TEXT(W) EOL(E). {VERIFY(ISEQ(V, "DA") && (ISEQ(W, "FA") || ISEQ(W, "QEA")) && ISEQ(E, "A"));}
EOL  ::= "[ABC]".
TEXT ::= "([^ABCE ]((E.)|.))+".
WS ::= " ".

%code {
  int main(int argc, char* argv[]) {
    TSTP("DA FA A");
    TSTP("DA QEA A");
//    TSTF("DA QETA A");
    TSTF("DA EA A");
    return leave();
  }
}
%endif

/******************************************/
%ifdef S_TST12
rModule ::= TEXT EOL.
EOL  ::= "[\.\!\?]".
TEXT ::= "((\\.)|(.))+".

%code {
  int main(int argc, char* argv[]) {
    TSTP("ABCED\\..");
    TSTP("ABCE\\.D.");
    TSTP("ABC\\.ED.");
    TSTP("AB\\.CED.");
    TSTP("A\\.BCED.");
    TSTP("\\.ABCED.");
    return leave();
  }
}
%endif

/******************************************/
%ifdef S_TST13
rModule ::= TEXT EOL TEXT EOL.
EOL  ::= "[\.\!\?]".
TEXT ::= "((\\.)|(.))+".
WS ::= "\r".
WS ::= "\n".
WS ::= "\r\n".

%code {
  int main(int argc, char* argv[]) {
    TSTP("ABC.\r\nDEF.");
    return leave();
  }
}
%endif

/******************************************/
%ifdef S_TST14
rModule ::= TEXT EOL.
EOL  ::= "[\.\!\?]".
TEXT ::= "((\\.)|(.))+".

%code {
  int main(int argc, char* argv[]) {
    TSTP("ABC\r\nDEF.");
    TSTP("ABC\\.DEF.");
    return leave();
  }
}
%endif

/******************************************/
%ifdef S_TST15

rModule ::= TEXT(V) EOL(E) TEXT(W) EOL(F). {VERIFY(ISEQ(V, "ABC") && (ISEQ(W, "DE3")||ISEQ(W, "DEF3")) && ISEQ(E, ".") && ISEQ(F, "."));}
rModule ::= TEXT(V) EOL(E). {VERIFY((ISEQ(V, "ABC\\. DE1")||ISEQ(V, "AC\\. DE2")||ISEQ(V, "ABC\\. DEF1")||ISEQ(V, "AB\\. DEF2")) && ISEQ(E, "."));}
EOL  ::= "[\.\!\?]".
TEXT ::= "([^\.\!\?]|(\\.))+".
WS ::= " ".

%code {
  int main(int argc, char* argv[]) {
    TSTP("ABC\\. DE1.");
    TSTP("AC\\. DE2.");
    TSTP("ABC. DE3.");
    TSTP("ABC\\. DEF1.");
    TSTP("AB\\. DEF2.");
    TSTP("ABC. DEF3.");
    return leave();
  }
}
%endif

/******************************************/
%ifdef S_TST16

rModule ::= TEXT(W) EOL(E). {VERIFY(ISEQ(W, "ABC D/EF") && ISEQ(E, "."));}
EOL  ::= "[\.\!\?]".
TEXT ::= "((\\.)|(.))+".

%code {
  int main(int argc, char* argv[]) {
    TSTP("ABC D/EF.");
    return leave();
  }
}
%endif

/******************************************/
%ifdef S_TST17
rModule ::= HWORD MWORD JWORD EOL.
EOL  ::= "[\.\!\?]".
HWORD ::= "à¤†à¤ª".
MWORD ::= "à¤®à¤¨à¥à¤·à¥à¤¯".
JWORD ::= "ãªã‹".
WS ::= " ".

%code {
  int main(int argc, char* argv[]) {
    TSTP("à¤†à¤ª à¤®à¤¨à¥à¤·à¥à¤¯ ãªã‹.");
    return leave();
  }
}
%endif

/******************************************/
%ifdef S_TST18

rModule ::= URL EOL.
EOL ::= "\n".
URL ::= "(http|ftp)://([^/\n]+)(/[^\n]*)?".

%code {
  int main(int argc, char* argv[]) {
    TSTP("http://www.google.com/\n");
    TSTP("http://www.google.co.in/\n");
    TSTP("http://www.google.com/index.html\n");
    TSTP("http://www.google.com/mail/index.html\n");
    return leave();
  }
}
%endif
