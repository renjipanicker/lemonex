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
  int rc = ParseReadString("http://www.google.co.in/mail/index.html\n", "<string>", "DBG_PREFIX:");
  if(rc != 0){
    printf("Error\n");
    return 1;
  }
  printf("Success\n");
  return 0;
}
}
