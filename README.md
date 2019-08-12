# Toy implementation of Post Script in D

ref: https://karino2.github.io/c-lesson/forth_modoki.html

## rules

- no runtime `-betterC`
- no free
- tiny and simple

## usage

run `dub run d-ps:<directory name>`

## demo

```
$ dub run d-ps:06_literal_name
Running ./d-ps_06_literal_name
>>> 1 2 add
3
>>> 2 3 add
5
>>> /abc 12 def
>>> 1 abc add
13
```
