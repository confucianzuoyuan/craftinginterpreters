#!/bin/sh

make book
rm -rf docs
cp -r site docs
cp zuoyuanimages/logotype.png docs/image/
cp zuoyuanimages/logotype-small.png docs/image/

python3 zuoyuan.py
