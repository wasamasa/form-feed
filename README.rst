form-feed
=========

About
-----

form-feed is a minor mode that displays pesky ``^L`` glyphs certain
developers use to delimit pages in the form of lines spanning the
entire window width.  It is also possible to display a less wide line
by customizing ``form-line-width`` before loading the package, see its
docstring for possible options.

Screenshot
----------

.. image:: https://raw.github.com/wasamasa/form-feed/master/img/scrot.png

Installation
------------

Install from `Marmalade <https://marmalade-repo.org/>`_ or `MELPA
(stable) <http://melpa.org/>`_ with ``M-x package-install RET
form-feed RET``.

Usage
-----

Enable the minor mode manually with ``M-x form-feed`` or in a hook:

.. code:: cl

    (add-hook 'emacs-lisp-mode-hook 'form-feed-mode)

Internals
---------

There are a bunch of ways of attacking the problem, one of the more
obscure ones is manipulating the display table of every window
displaying the buffer.  Unfortunately this approach is limited to
replacing a glyph with an array of other glyphs, but guaranteed to
work on non-graphical display as well.  The other approach is putting
an overlay or text property over the glyph which manipulates its look.
Since a face on its own won't do the trick, this package uses a lesser
known feature of font-lock that allows one to add text properties as
part of the face definition associated with the page delimiter glyph
and tells it to remove those on fontification changes to make sure
disabling works equally well.  This also means that while this package
is conceptually very simple and non-invasive, it might not work on
non-graphical displays.  As a workaround I've made Emacs use
underlining instead of strike-through on such displays.

The implementation of display lines was inspired by the `magic-buffer
<https://github.com/sabof/magic-buffer>`_ package, but did eventually
remove its "cursor kicking" due to a rather puzzling bug.

Contributing
------------

If you find bugs, have suggestions or any other problems, feel free to
report an issue on the issue tracker or hit me up on IRC, I'm always on
``#emacs``.  Patches are welcome, too, just fork, work on a separate
branch and open a pull request with it.

Alternatives
------------

- `formfeed-hline <http://user42.tuxfamily.org/formfeed-hline/index.html>`_
  is probably the oldest package of them all, sports XEmacs
  compatibility and modifies the display table to add a line of dashes
  after the ``^L`` glyph.

- `Pretty Control L <http://www.emacswiki.org/emacs/PrettyControlL>`_
  is similiarly old and modifies the display table in a more elaborate
  way to turn the ``^L`` glyph into something resembling a section.

- `page-break-lines <https://github.com/purcell/page-break-lines>`_ is
  the newest package available using the display table approach and
  the one I'd recommend if this package doesn't work for you in
  non-graphical Emacs sessions.

- `Overlay Control L <http://www.emacswiki.org/emacs/OverlayControlL>`_
  is what inspired me to take the font-lock route.  However installing
  an overlay feels too heavyweight to me, additionally to that it's not
  trivial to clean them up afterwards.
