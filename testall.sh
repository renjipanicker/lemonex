LDBG=0
ALLT=0

MLIST=`grep "%ifdef *" test.y | cut -f 2 -d " "`
ALIST=
while [[ "$1" != "" ]]; do
  case $1 in
    -d )
        LDBG=1
        ;;
    -dd )
        LDBG=2
        ;;
    -a )
        ALLT=1
        ;;
    * )
        ALIST="$ALIST $1"
        MLIST=$ALIST
        ;;
  esac
  shift
done

rm -f test.c test.h test.out

PLIST=
FLIST=

function chk {
  STGE=$1
  RECV=$2
  MODE=$3
  MESG=$4
  EXPT=${MODE:0:1}
  case $EXPT in
    S)
      if [ $RECV -ne 0 ]; then
        if [ $ALLT -eq 0 ]; then
          echo $MESG
          exit 1
        fi
        FLIST="$FLIST $MODE"
        return 1
      fi
      ;;
    G)
      if [ $RECV -eq 0 ]; then
        if [ $ALLT -eq 0 ]; then
          echo $MESG
          exit 1
        fi
        FLIST="$FLIST $MODE"
        return 1
      fi
      ;;
    C)
      if [ $RECV -eq 0 ]; then
        if [ $ALLT -eq 0 ]; then
          echo $MESG
          exit 1
        fi
        FLIST="$FLIST $MODE"
        return 1
      fi
      ;;
    R)
      if [ $RECV -eq 0 ]; then
        if [ $ALLT -eq 0 ]; then
          echo $MESG
          exit 1
        fi
        FLIST="$FLIST $MODE"
        return 1
      fi
      ;;
    *)
      echo "Unknown stage $EXPT"
      exit 1
  esac
  if [ $STGE == $EXPT ]; then
    return 1
  fi
  return 0
}

clang -g -DLEMONEX_DBG=$LDBG -o ./lemon.osx ./lemon.c
if [ $? -ne 0 ]; then
  echo error compiling lemon
  exit 1
fi

for MODE in $MLIST; do
  ./lemon.osx T=./lempar.c D=$MODE d=./ test.y
  chk G $? $MODE "error generating parser in $MODE"
  if [ $? -ne 0 ]; then
    continue
  fi

  clang -g -D$MODE -o test test.c
  chk C $? $MODE "error compiling parser in $MODE"
  if [ $? -ne 0 ]; then
    continue
  fi

  ./test
  chk R $? $MODE "error running parser in $MODE"

  PLIST="$PLIST $MODE"
  echo DONE:$MODE
done

if [ $ALLT -ne 0 ]; then
  echo "PASSED:[$PLIST]"
  echo "FAILED:[$FLIST]"
fi
