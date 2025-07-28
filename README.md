# vim-specialcolor

## Specialized highlighting for matched tags, CSS colors...
vim-specialcolor is a Vim plugin that provides two main features:
1. HTML/XML tag matching highlighting
2. CSS color code highlighting with actual color display

## Features
1. Tag Matching Highlighting
    - Highlights matching HTML/XML tags when cursor is on a tag
    - Supports self-closing tags
    - Works with multiple filetypes (HTML, XML, XHTML, Vue, JSX, etc.)

2. CSS Color Code Highlighting
    - Displays actual colors for:
        - Hex codes (#RGB, #RRGGBB)
        - RGB values (rgb(255, 0, 0))
        - RGBA values (rgba(255, 0, 0, 0.5))
    - Automatically adjusts text color for readability (black or white) based on background color

## Screenshot
![Viewmap Screenshot](https://github.com/bleakwind/vim-specialcolor/blob/main/vim-specialcolor.png)

## Requirements
Recommended Vim 8.1+

## Installation
```vim
" Using Vundle
Plugin 'bleakwind/vim-specialcolor'
```

And Run:
```vim
:PluginInstall
```

## Configuration
Add these to your `.vimrc`:

specialcolor_matchtag
```vim
" Set 1 enable matchtag highlight (default: 0)
let g:specialcolor_matchtag_enabled = 1
" Search range for color preview (default: 100 lines)
let g:specialcolor_matchtag_range = 100
" Set matchtag trigger delay in milliseconds (default: 100)
let g:specialcolor_matchtag_updelay = 100
```

specialcolor_csscolor
```vim
" Set 1 enable csscolor highlight (default: 0)
let g:specialcolor_csscolor_enabled = 1
" Search range for color preview (default: 100 lines)
let g:specialcolor_csscolor_range = 100
" Set csscolor trigger delay in milliseconds (default: 200)
let g:specialcolor_csscolor_updelay = 200
```

Highlight configuration
```vim
" Set matchtag highlight details
hi SpecialcolorMatchtag ctermfg=Black ctermbg=Red cterm=NONE guifg=#000000 guibg=#FF939C gui=NONE
```

## License
BSD 2-Clause - See LICENSE file
