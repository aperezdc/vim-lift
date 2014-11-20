========
vim-lift
========

This is a “completion” system for Vim_ and NeoVim_. It does not do
completion by itself, but it aggregates (“lifts” up) completion
candidates from other completion sources and makes the completion
popup show an unified list of candidates.

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
