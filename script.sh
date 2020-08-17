#!/bin/sh

set -ex

mkdir -p out
nvram -xp > out/nvram.xml
