<h1>Lemonex</h1>

Lemonex is an extension to the lemon parser, developed to include a builtin lexer.

The following is a minimal example:
```
%include {
#include <assert.h>
#include <stdlib.h>
#include <string.h>
}

%start_symbol rModule
rModule ::= URL EOL.
EOL ::= "\n".
URL ::= "(http|ftp)://([^/\n]+)(/[^\n]*)?".

%code {
int main(int argc, char* argv[]) {
  int rc = ParseReadString("http://www.google.co.in/mail/index.html\n", "<string>", "DBG_PREFIX:"); \
  if(rc != 0){
    printf("Error\n");
    return 1;
  }
  printf("Success\n");
  return 0;
}
}
```

<h2>Symbol definition</h2>
Lemonex automatically matches the symbol on the LHS to any symbol of the same name defined in the grammar. It generates warning on symbols that do not have a regex defined.
Any regex that does not have a symbol in the grammar is ignored. This is useful for comments, whitespace, etc.

<h2>Integration</h2>
The lexer can be invoked in 2 ways:
  #  Standalone: In this mode, the lexer is created and invoked as an independent object, just like the parser.
  #  Integrated: In this mode, the lexer is automatically created when the parser is created.
The integration mode is defined using %lexer_integration (values are ON or OFF).

<h2>Wrapper functions</h2>
Lemon provides 2 wrapper functions, for reading strings and files respectively. These functions wrap the lexer and parser conveniently. These functions are:
  #  ParseReadString()
  #  ParseReadFile()
where Parse is replaced by the prefix specified by %name

<h2>Lexer modes</h2>
It can work in multiple lexer modes. The modes are defined by the %lexer_mode command, as follows:

```
%start_symbol rModule
rModule ::= URL EOL.
EOL ::= "\n".
URL ::= "(http|ftp)://([^/\n]+)(/[^\n]*)?".
ENTER_MLCOMMENT ::= "/\*". [MLCOMMENT]

%lexer_mode MLCOMMENT.
ENTER_MLCOMMENT ::= "/\*". [MLCOMMENT]
LEAVE_MLCOMMENT ::= "\*/". [<]
WS ::= ".*".
```

The lexer starts in the first mode which has been defined. If no mode was explicitly defined, a default mode named INITMODE is created.

In the example above, ENTER_MLCOMMENT is a pseudo-symbol (not defined in the grammar), which causes the lexer to switch to MLCOMMENT mode when it reads a /* on the input stream.

In MLCOMMENT mode, if it sees another /* it recursively enters the same mode. If it sees a */, it returns to the previous mode, specified by <

This makes handling of nested multiline comments easy.
The nesting depth is defined using %lexer_nestingdepth, with a default value of 32.

<h2>Regular expressions</h2>
Lemonex works with a subset of the regular expression syntax. It can handle *, + and ? operators, as well as [] for defining classes, and () for grouping.

Further, Lemonex supports limited capture functionality. for example:
```
STRING ::= !"'" ".*" !"'".
```
This defines a string defined within single quotes. The single quotes are defined separately, prefixed with an exclamation indicating that it should be added to the captured text.

Lemonex has a limitation, in that the capture definition cannot overlap. For example:
```
STRING1 ::= !"'" "ABC" !"'".
STRING2 ::=  "'" "DEF"  "'".
```
This will give an error. Since Lemonex has a lookahead of 1 and cannot backtrack, it cannot go back and re-capture the quote when it realises that the input will not match STRING1.

<h2>Regular expression classes</h2>
It can handle a few classes such as:
  #  \l (letters)
  #  \d (digits)
  #  \s (spaces, tabs)

<h2>Regular expression loop exit</h2>
Lemonex has two mechanisms for breaking out of * loops.
For regular expressions that end with a dot-star, such as:
```
EOL ::= "?".
STRING ::=  "ABC.*".
WS ::= " ".
```
It will read the input ABC, and then keep reading characters until it finds either a ? or a space. That is, until it finds any character that starts another symbol in the current mode.

Whereas for regular expressions that end with a not-star, such as:
```
EOL ::= "?".
STRING ::=  "ABC[^;]*".
WS ::= " ".
```
It will keep reading the input, including any ? or spaces, until it finds a ;

<h2>Default token</h2>
It defines a default token structure called lxToken (defined in lempar.c), which contains the following members:
  #  filename: the current file name (blank if reading from a string)
  #  row/col: the row/column - Lemonex can handle newlines and keep row/column counts.
  #  but: and the captured token text - by default, Lemonex uses malloc/free to automatically maintain the current capture buffer.
This structure is used by default, but can be overridden by the %token_type directive provided by the lemon parser.

<h2>Default token constructor</h2>
Lemonex has a %token_constructor block, defined as a counterpart to the %token_destructor block.
The function for this block is defined in the lempar.c file, and is used only if the default token is not overridden by %token_type.
This block is called whenever
  #  a token needs to be initialised
  #  a character needs to be captured
  #  and a token needs to be finalised before sending to the parser.

<h2>Action code</h2>
Lemonex supports match actions, code that executes when any symbol is matched. This is similar to the reduce action defined in the grammar. This allows the capture to be modified before it gets sent to the parser. For example:
```
WORD ::= "[\r\n\t ]+". {$$.buf[0] = ' ';$$.buf[1] = 0;}
```
This code converts any whitespace character including newlines, to a single space before getting sent to the parser.

<h2>Lexer code</h2>
Lemon allows one to define a code block using %lexer_code. This is similar to the %code block, expect that it gets generated between the parser and lexer in the output file.
This allows one to define function and other constructs that can be accessed from the lexer, and which can in turn access constructs defined as a part of the parser.

<h2>Unicode handling</h2>
Lemonex can handle UTF8 natively. For example:
```
rModule ::= HINDI_WORD JAPANESE_WORD EOL.
EOL  ::= "[\.\!\?]".
HINDI_WORD ::= "आप".
JAPANESE_WORD ::= "なか".
WS ::= " ".
```
Lemonex has full support for Unicode letter, digit and space character classes.

<h2>Miscellaneous</h2>
  #  Lemonex suppresses generation of an external header file, regardless of the -m setting. It instead generates all the #define's within the generated .c file, again regardless of the -m setting.
  #  Totally unrelated to lexing, lemonex allows to specify the output directory(-d) and extention(-e). This eases the usage in project files where a .cpp file is required, within a specific output directory.

<h2>Technical information</h2>
Lemonex has a lookahead of 1, with fail state.

It starts with an empty DFA, and works in 3 stages: preprocess, process, and postprocess.
  #  In the preprocess stage, it converts the input regex string to an intermediate AST (See grammar here [ASTGrammar])
  #  In the process stage, it traverses the AST recursively, adding states and transitions to the DFA.
  #  In the postprocess stage, it traverses the DFA and adds fail states to each state.

The lexer extension feature is enabled in the code by #defining LEMONEX to 1

Lemonex has 3 debug levels - 0, 1 and 2, indicating increasing levels of debug info that gets generated. This is defined in the LEMONEX_DBG preprocessor variable in lemon.c.

In LEMONEX mode, the error token is always enabled, and used on lexer error.

Lemonex has been developed against the most recent commit on sqlite3 trunk as of 22nd June 2015.
