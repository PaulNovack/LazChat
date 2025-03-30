#!/bin/sh
DoExitAsm ()
{ echo "An error occurred while assembling $1"; exit 1; }
DoExitLink ()
{ echo "An error occurred while linking $1"; exit 1; }
echo Assembling lazchat
/Library/Developer/CommandLineTools/usr/bin/clang -x assembler -c -target arm64-apple-macosx11.0.0 -o /Users/paulnovack/code/OpenAILazarus2/lib/aarch64-darwin/lazchat.o  -x assembler /Users/paulnovack/code/OpenAILazarus2/lib/aarch64-darwin/lazchat.s
if [ $? != 0 ]; then DoExitAsm lazchat; fi
rm /Users/paulnovack/code/OpenAILazarus2/lib/aarch64-darwin/lazchat.s
echo Linking /Users/paulnovack/code/OpenAILazarus2/lazchat
OFS=$IFS
IFS="
"
/Library/Developer/CommandLineTools/usr/bin/ld     -framework Cocoa -weak_framework UserNotifications      -order_file /Users/paulnovack/code/OpenAILazarus2/symbol_order.fpc -multiply_defined suppress -L. -o /Users/paulnovack/code/OpenAILazarus2/lazchat `cat /Users/paulnovack/code/OpenAILazarus2/link39470.res` -filelist /Users/paulnovack/code/OpenAILazarus2/linkfiles39470.res
if [ $? != 0 ]; then DoExitLink /Users/paulnovack/code/OpenAILazarus2/lazchat; fi
IFS=$OFS
