========
vim-lift
========

This is a “completion” system for Vim_ and NeoVim_. It does not do
completion by itself, but it aggregates (“lifts” up) completion
candidates from other completion sources and makes the completion
popup show an unified list of candidates.

Sources
=======

The following plug-ins are known to work well as completion sources
out of the box (no manual configuration needed):

- [clang_complete](https://github.com/Rip-Rip/clang_complete)
- [jedi](https://github.com/davidhalter/jedi-vim)
- [YouCompleteMe](https://valloric.github.io/YouCompleteMe/)
- [vim-ledger](https://github.com/ledger/vim-ledger)

Make sure to check the documentation (section `lift-tips`) for additional
information on how to configure those plug-ins to be used as completion
sources.


Installation
============

Using NeoBundle_
----------------

1. Add ``NeoBundle 'aperezdc/vim-lift'`` to ``~/.vimrc``


Using Vundle_
-------------

1. Add ``Plugin 'aperezdc/vim-lift'`` to ``~/.vimrc``
2. Run ``vim +PluginInstall +qall``

Using Pathogen_
---------------

Execute the following commands:

1. ``cd ~/.vim/bundle``
2. ``git clone https://github.com/aperezdc/vim-lift``


.. _vim: http://www.vim.org
.. _neovim: http://neovim.org
.. _neobundle: https://github.com/Shougo/neobundle.vim
.. _vundle: https://github.com/gmarik/vundle
.. _pathogen: https://github.com/tpope/vim-pathogen
