#!/bin/sh

make book
rm -rf docs
cp -r site docs
