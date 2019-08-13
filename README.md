# Toy implementation of Post Script in D

[![CircleCI](https://circleci.com/gh/ShigekiKarita/d-ps.svg?style=svg)](https://circleci.com/gh/ShigekiKarita/d-ps)
[![codecov](https://codecov.io/gh/ShigekiKarita/d-ps/branch/master/graph/badge.svg)](https://codecov.io/gh/ShigekiKarita/d-ps)

ref: https://karino2.github.io/c-lesson/forth_modoki.html

## rules

- no runtime `-betterC`
- no library (except for C standard library in `core.stdc`)
- tiny and simple

## usage

- run repl: `dub run d-ps:<directory name>`
- run test: `dub test d-ps:<directory name>`

## demo

```
$ dub run d-ps:10_control_stack
Building package d-ps:10_control_stack in /home/skarita/Documents/repos/d-ps/
Performing "debug" build using /home/skarita/dlang/dmd-2.084.1/linux/bin64/dmd for x86_64.
d-ps:10_control_stack ~master: building configuration "application"...
Linking...
Running ./d-ps_10_control_stack 
>>> /abc 0 def
>>> abc
0
>>> abc 1 2 ifelse
2
>>> /abc 1 def 
>>> abc 1 2 ifelse
1
>>> /addone {1 add} def
>>> 3 addone
4
```
