#!/bin/bash

pwd
cd ./latex/section/$1

text="%%$1"

for f in *[!.backup]
do
	text="$text\n\n\\subimport{$1/}{$f}\n\\\\FloatBarrier\n"
done

printf $text > ../$1.tex


