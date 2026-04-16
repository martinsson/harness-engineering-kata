#!/bin/bash
git clone https://github.com/jayrm/fbcunit.git
cd fbcunit
make
cp inc/* ../inc/
cp lib/* ../lib/
cd ..
rm -r fbcunit
