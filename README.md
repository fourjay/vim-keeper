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

keeper provides a mapping and commandm, neither of which should conflict with
most setups.

*MAPPING*
`KK` does context sensitive search for documentation. This is obviously
modeled on vim's existing keyword map.

*COMMAND*
`:WebMan` does a context sensitive lookup on an arbitrary keyword.

## Caveats
keeper expects a unix shell, and works best with some sort of text
browser (it understands lynx, w3m, elink and links)
