vim-keeper
==========

Simple integrated documentation viewer inspired by investigate It is intended
to work with a browser that outputs text, but it will call an external
graphical utility.

## Motivation

I've always liked the idea of keyword lookup, but it's always felt a bit
awkward in practice. It shells out quite visibly. The shell makes it cumbersome
to flip back and forth. There is  a tool mental context switch, man does not
have the same command set as vim, and copy paste function depends on yet
another tool (X-Windows or screen multiplexing). Further, it doesn't
account for it's most obvious use case, looking up new code. The use
case that it seems best suited for is examining existing code.

If I imagined a documentation tool, I'd want it to open in a vim buffer, and to
provide useful help "automagically". This comes pretty close.

## Features

* Useful results out of the box
* Context sensitive
* Help is in buffer. Cut and paste
* Allows freeform searching
* Is text based
* Leverages standard .vimrc configuration stanzas to modify behavior.

## Usage

keeper provides a mapping and commands, neither of which should conflict with
most setups. KK is mapped as a (more or less) replacement for the stock K
without stepping on existing K mappings

*MAPPINGS*
`KK` does context sensitive search for documentation. This is obviously
modeled on vim's existing keyword map.

*COMMANDS*

`:Lookup` does a context sensitive lookup on the current word

`:Help` does a context sensitive lookup on an arbitrary keyword.

`:Wikipedia STRING` searches wikipedia for STRING

`:Thesaurus STRING` searches online thesaurus for STRING

## Caveats
Requires a text based browser command somewhere in your path.
Supports w3m, lynx, elinks, links and will fall back to curl or wget

**OTHER**

    https://github.com/yuratomo/w3m.vim
    A fairly feature complete wrapper around w3m
