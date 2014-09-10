#! /usr/bin/sh
ANSI_COLORS_DISABLED=1 PATT='Horizontal rules' perl runtests.pl spec.txt 'perl ./commonmark.pl' 2>&1 > commonmark.out
