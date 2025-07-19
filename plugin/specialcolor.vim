" vim: set expandtab tabstop=4 softtabstop=4 shiftwidth=4: */
"
" +--------------------------------------------------------------------------+
" | $Id: specialcolor.vim 2025-05-23 02:30:17 Bleakwind Exp $                |
" +--------------------------------------------------------------------------+
" | Copyright (c) 2008-2025 Bleakwind(Rick Wu).                              |
" +--------------------------------------------------------------------------+
" | This source file is specialcolor.vim.                                    |
" | This source file is release under BSD license.                           |
" +--------------------------------------------------------------------------+
" | Author: Bleakwind(Rick Wu) <bleakwind@qq.com>                            |
" +--------------------------------------------------------------------------+
"

if exists('g:specialcolor_plugin') || &compatible
    finish
endif
let g:specialcolor_plugin = 1

scriptencoding utf-8

let s:save_cpo = &cpoptions
set cpoptions&vim

" ============================================================================
" 01: specialcolor_matchtag setting
" ============================================================================
let g:specialcolor_matchtag_enabled     = get(g:, 'specialcolor_matchtag_enabled', 0)
let g:specialcolor_matchtag_range       = get(g:, 'specialcolor_matchtag_range', 100)
let g:specialcolor_matchtag_updelay     = get(g:, 'specialcolor_matchtag_updelay', 100)
let g:specialcolor_matchtag_filetype    = get(g:, 'specialcolor_matchtag_filetype', ['htm', 'html', 'xml', 'xhtml', 'vue', 'jsx', 'javascript', 'typescript', 'javascriptreact', 'typescriptreact'])
let g:specialcolor_matchtag_selftag     = get(g:, 'specialcolor_matchtag_selftag', ['area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input', 'link', 'meta', 'param', 'source', 'track', 'wbr'])

let g:specialcolor_matchtag_matchid     = []
let g:specialcolor_matchtag_hlname      = 'SpecialcolorMatchtag'
let g:specialcolor_matchtag_timer       = -1

if !hlexists('SpecialcolorMatchtag') | hi default link SpecialcolorMatchtag MatchParen | endif

" ============================================================================
" 02: specialcolor_csscolor setting
" ============================================================================
let g:specialcolor_csscolor_enabled     = get(g:, 'specialcolor_csscolor_enabled', 0)
let g:specialcolor_csscolor_range       = get(g:, 'specialcolor_csscolor_range', 100)
let g:specialcolor_csscolor_updelay     = get(g:, 'specialcolor_csscolor_updelay', 200)

let g:specialcolor_csscolor_matchid     = []
let g:specialcolor_csscolor_timer       = -1

" ============================================================================
" 01: specialcolor_matchtag detail
" g:specialcolor_matchtag_enabled = 1
" ============================================================================
if exists('g:specialcolor_matchtag_enabled') && g:specialcolor_matchtag_enabled == 1

    " --------------------------------------------------
    " specialcolor#MatchtagSetHltag
    " --------------------------------------------------
    function! specialcolor#MatchtagSetHltag() abort
        if g:specialcolor_matchtag_timer != -1
            call timer_stop(g:specialcolor_matchtag_timer)
            let g:specialcolor_matchtag_timer = -1
        endif
        let g:specialcolor_matchtag_timer = timer_start(g:specialcolor_matchtag_updelay, {-> execute('call specialcolor#MatchtagSetHlcon()', '')})
    endfunction

    " --------------------------------------------------
    " specialcolor#MatchtagSetHlcon
    " --------------------------------------------------
    function! specialcolor#MatchtagSetHlcon() abort
        if index(g:specialcolor_matchtag_filetype, &filetype) != -1
            let [l:tag_name, l:tag_type, l:tag_pos] = specialcolor#MatchtagGetCursortag()
            if !empty(l:tag_name)
                if empty(g:specialcolor_matchtag_matchid) || !exists('s:last_tag') || s:last_tag != [l:tag_name, l:tag_type, l:tag_pos]
                    let s:last_tag = [l:tag_name, l:tag_type, l:tag_pos]
                    call specialcolor#MatchtagClearHltag()
                    if index(g:specialcolor_matchtag_selftag, l:tag_name) != -1
                        call specialcolor#MatchtagSetHlpostag(l:tag_pos)
                    else
                        if l:tag_type ==# 'open'
                            let l:match_pos = specialcolor#MatchtagGetClosetag(l:tag_name, l:tag_pos)
                        elseif l:tag_type ==# 'close'
                            let l:match_pos = specialcolor#MatchtagGetOpentag(l:tag_name, l:tag_pos)
                        endif
                        if !empty(l:match_pos)
                            call specialcolor#MatchtagSetHlpostag(l:tag_pos)
                            call specialcolor#MatchtagSetHlpostag(l:match_pos)
                        endif
                    endif
                endif
            else
                call specialcolor#MatchtagClearHltag()
            endif
        endif
    endfunction

    " --------------------------------------------------
    " specialcolor#MatchtagSetHlpostag
    " --------------------------------------------------
    function! specialcolor#MatchtagSetHlpostag(pos) abort
        let [l:lnum, l:start_col, l:finish_col] = a:pos
        let l:conlist = getline(l:lnum)
        let l:context = l:conlist[l:start_col-1 : l:finish_col-1]

        if l:context[1] == '/'
            let l:hl_text = '</'.matchstr(l:context, '^<\/\zs[^ >]\+>\ze')
            let l:hl_start = stridx(l:context, l:hl_text)
            let l:hl_len = len(l:hl_text) - 1
        else
            let l:hl_text = '<'.matchstr(l:context, '^<\zs[^ >]\+\ze')
            let l:hl_start = stridx(l:context, l:hl_text)
            let l:hl_len = len(l:hl_text) - 1
        endif

        if l:hl_start != -1
            let l:match_id = matchaddpos(g:specialcolor_matchtag_hlname, [[l:lnum, l:start_col + l:hl_start, l:hl_start + l:hl_len + 1]])
            call add(g:specialcolor_matchtag_matchid, l:match_id)
        endif
    endfunction

    " --------------------------------------------------
    " specialcolor#MatchtagClearHltag
    " --------------------------------------------------
    function! specialcolor#MatchtagClearHltag() abort
        for il in g:specialcolor_matchtag_matchid
            silent! call matchdelete(il)
        endfor
        let g:specialcolor_matchtag_matchid = []
    endfunction

    " --------------------------------------------------
    " specialcolor#MatchtagGetCursortag
    " --------------------------------------------------
    function! specialcolor#MatchtagGetCursortag() abort
        let l:conlist = getline('.')
        let l:colpos = col('.')

        let l:open_pos = strridx(l:conlist[:l:colpos-1], '<')
        if l:open_pos == -1 | return ['', '', []] | endif

        let l:close_pos = stridx(l:conlist[l:open_pos:], '>') + l:open_pos
        if l:close_pos <= l:open_pos | return ['', '', []] | endif

        let l:tag_str = l:conlist[l:open_pos : l:close_pos]
        let l:tag_name = matchstr(l:tag_str, '^<\/\?\zs[^ >/]\+\ze')
        if empty(l:tag_name) | return ['', '', []] | endif

        let l:tag_type = l:tag_str[1] == '/' ? 'close' : 'open'
        return [l:tag_name, l:tag_type, [line('.'), l:open_pos + 1, l:close_pos + 1]]
    endfunction

    " --------------------------------------------------
    " specialcolor#MatchtagGetOpentag
    " --------------------------------------------------
    function! specialcolor#MatchtagGetOpentag(tagname, closepos) abort
        let [l:lnum, l:lcol, _] = a:closepos
        let l:line_res = 1
        let l:line_cur = l:lnum
        let l:line_min = max([1, l:lnum - g:specialcolor_matchtag_range])

        " find before tag_close
        let l:find_pos = [l:lnum, l:lcol - 1]

        while l:line_cur >= l:line_min
            let l:conlist = getline(l:line_cur)
            let l:start = (l:line_cur == l:lnum) ? l:lcol - 1 : len(l:conlist) - 1

            while l:start >= 0
                " find tag_close
                let l:tag_close = matchstr(l:conlist[:l:start], '</'.a:tagname.'\>')
                if !empty(l:tag_close)
                    let l:line_res += 1
                    let l:start = strridx(l:conlist[:l:start], l:tag_close) - 1
                    continue
                endif
                " find tag_open
                let l:tag_open = matchstr(l:conlist[:l:start], '<'.a:tagname.'\>')
                if !empty(l:tag_open)
                    let l:line_res -= 1
                    if l:line_res == 0
                        " find match tag_open
                        let l:open_pos = strridx(l:conlist[:l:start], l:tag_open)
                        return [l:line_cur, l:open_pos + 1, l:open_pos + len(l:tag_open) + 1]
                    endif
                    let l:start = strridx(l:conlist[:l:start], l:tag_open) - 1
                    continue
                endif
                " next
                let l:start -= 1
            endwhile

            let l:line_cur -= 1
            let l:start = len(getline(l:line_cur)) - 1
        endwhile
        return []
    endfunction

    " --------------------------------------------------
    " specialcolor#MatchtagGetClosetag
    " --------------------------------------------------
    function! specialcolor#MatchtagGetClosetag(tagname, openpos) abort
        let [l:lnum, l:lcol, _] = a:openpos
        let l:line_res = 1
        let l:line_cur = l:lnum
        let l:line_max = min([line('$'), l:lnum + g:specialcolor_matchtag_range])

        " find after tag_open
        let l:find_pos = [l:lnum, l:lcol + 1]

        while l:line_cur <= l:line_max
            let l:conlist = getline(l:line_cur)
            let l:start = (l:line_cur == l:lnum) ? l:lcol : 0

            while l:start < len(l:conlist)
                " find tag_open
                let l:tag_open = matchstr(l:conlist[l:start:], '<'.a:tagname.'\>')
                if !empty(l:tag_open)
                    let l:line_res += 1
                    let l:start += stridx(l:conlist[l:start:], l:tag_open) + len(l:tag_open)
                    continue
                endif
                " find tag_close
                let l:tag_close = matchstr(l:conlist[l:start:], '</'.a:tagname.'\>')
                if !empty(l:tag_close)
                    let l:line_res -= 1
                    if l:line_res == 0
                        " find match tag_close
                        let l:close_pos = l:start + stridx(l:conlist[l:start:], l:tag_close)
                        return [l:line_cur, l:close_pos + 1, l:close_pos + len(l:tag_close) + 1]
                    endif
                    let l:start += stridx(l:conlist[l:start:], l:tag_close) + len(l:tag_close)
                    continue
                endif
                " next
                let l:start += 1
            endwhile

            let l:line_cur += 1
            let l:start = 0
        endwhile

        return []
    endfunction

    " --------------------------------------------------
    " specialcolor_cmd_matchtag_bas
    " --------------------------------------------------
    augroup specialcolor_cmd_matchtag_bas
        autocmd!
        autocmd CursorMoved,CursorMovedI,TextChanged,TextChangedI * call specialcolor#MatchtagSetHltag()
        autocmd BufLeave * call specialcolor#MatchtagClearHltag()
    augroup END

endif

" ============================================================================
" 02: specialcolor_csscolor detail
" g:specialcolor_csscolor_enabled = 1
" ============================================================================
if exists('g:specialcolor_csscolor_enabled') && g:specialcolor_csscolor_enabled == 1

    " --------------------------------------------------
    " specialcolor#CsscolorSetColor
    " --------------------------------------------------
    function! specialcolor#CsscolorSetColor() abort
        let l:bufnbr = bufnr('%')
        let l:buflist = filter(range(1, bufnr('$')), 'buflisted(v:val) && getbufvar(v:val, "&buftype") == ""')
        if index(l:buflist, l:bufnbr) != -1
            if g:specialcolor_csscolor_timer != -1
                call timer_stop(g:specialcolor_csscolor_timer)
                let g:specialcolor_csscolor_timer = -1
            endif
            let g:specialcolor_csscolor_timer = timer_start(g:specialcolor_csscolor_updelay, {-> execute('call specialcolor#CsscolorSetCon()', '')})
        endif
    endfunction

    " --------------------------------------------------
    " specialcolor#CsscolorSetCon
    " --------------------------------------------------
    function! specialcolor#CsscolorSetCon() abort
        " clear color
        call specialcolor#CsscolorClearColor()
        " set color
        let l:curr_line = line('.')
        let l:start_line = max([1, l:curr_line - g:specialcolor_csscolor_range])
        let l:end_line = min([line('$'), l:curr_line + g:specialcolor_csscolor_range])

        call specialcolor#CsscolorSetHex(l:start_line, l:end_line)
        call specialcolor#CsscolorSetRgb(l:start_line, l:end_line)
        call specialcolor#CsscolorSetRgba(l:start_line, l:end_line)
    endfunction

    " --------------------------------------------------
    " specialcolor#CsscolorClearColor
    " --------------------------------------------------
    function! specialcolor#CsscolorClearColor() abort
        for il in g:specialcolor_csscolor_matchid
            silent! call matchdelete(il)
        endfor
        let g:specialcolor_csscolor_matchid = []
    endfunction

    " --------------------------------------------------
    " specialcolor#CsscolorSetHex
    " --------------------------------------------------
    function! specialcolor#CsscolorSetHex(start_line, end_line) abort
        let l:currpos = getpos('.')
        let l:conlist = getline(a:start_line, a:end_line)
        let l:lnum = a:start_line - 1

        for il in l:conlist
            let l:lnum += 1
            let l:lcol = 0

            while 1
                " find [#RGB|#RRGGBB]
                let l:find_str = matchstrpos(il, '#[0-9a-fA-F]\{3\}\>\|#[0-9a-fA-F]\{6\}\>', l:lcol)
                if l:find_str[1] == -1 | break | endif

                let [l:code, l:start, l:finish] = l:find_str
                let l:lcol = l:finish

                " create highlight
                let l:hl_group = 'SpecialColorHex_'.l:lnum.'_'.l:start
                let l:bg_color = specialcolor#CsscolorHexFix(l:code)
                let l:term_color = specialcolor#CsscolorHexTerm(l:code)

                if !empty(l:bg_color)
                    let l:fg_color = specialcolor#CsscolorCalcFg(l:bg_color)
                    execute 'hi '.l:hl_group.' guibg='.l:bg_color.' guifg='.l:fg_color.' ctermbg='.l:term_color.' ctermfg='.(l:fg_color == 'White' ? '15' : '0')
                    let l:match_id = matchadd(l:hl_group, '\%'.l:lnum.'l\%'.(l:start+1).'c'.l:code)
                    call add(g:specialcolor_csscolor_matchid, l:match_id)
                endif
            endwhile
        endfor

        call setpos('.', l:currpos)
    endfunction

    " --------------------------------------------------
    " specialcolor#CsscolorSetRgb
    " --------------------------------------------------
    function! specialcolor#CsscolorSetRgb(start_line, end_line) abort
        let l:currpos = getpos('.')
        let l:conlist = getline(a:start_line, a:end_line)
        let l:lnum = a:start_line - 1

        for il in l:conlist
            let l:lnum += 1
            let l:lcol = 0

            while 1
                let l:find_str = matchstrpos(il, 'rgb(\s*\d\+\%(\s*,\s*\d\+\)\{2\}\s*)', l:lcol)
                if l:find_str[1] == -1 | break | endif

                let [l:code, l:start, l:finish] = l:find_str
                let l:lcol = l:finish

                let l:hl_group = 'SpecialColorRGB_'.l:lnum.'_'.l:start
                let l:bg_color = specialcolor#CsscolorRgbFix(l:code)

                if !empty(l:bg_color)
                    let l:fg_color = specialcolor#CsscolorCalcFg(l:bg_color)
                    execute 'hi '.l:hl_group.' guibg='.l:bg_color.' guifg='.l:fg_color
                    let l:match_id = matchadd(l:hl_group, '\%'.l:lnum.'l\%'.(l:start+1).'c'.l:code)
                    call add(g:specialcolor_csscolor_matchid, l:match_id)
                endif
            endwhile
        endfor

        call setpos('.', l:currpos)
    endfunction

    " --------------------------------------------------
    " specialcolor#CsscolorSetRgba
    " --------------------------------------------------
    function! specialcolor#CsscolorSetRgba(start_line, end_line) abort
        let l:currpos = getpos('.')
        let l:conlist = getline(a:start_line, a:end_line)
        let l:lnum = a:start_line - 1

        for il in l:conlist
            let l:lnum += 1
            let l:lcol = 0
            while 1
                let l:find_str = matchstrpos(il, 'rgba(\s*\d\+\%(\s*,\s*\d\+\)\{3\}\s*)', l:lcol)
                if l:find_str[1] == -1 | break | endif

                let [l:code, l:start, l:finish] = l:find_str
                let l:lcol = l:finish

                let l:hl_group = 'SpecialColorRGBA_'.l:lnum.'_'.l:start
                let l:bg_color = specialcolor#CsscolorRgbaFix(l:code)

                if !empty(l:bg_color)
                    let l:fg_color = specialcolor#CsscolorCalcFg(l:bg_color)
                    execute 'hi '.l:hl_group.' guibg='.l:bg_color.' guifg='.l:fg_color
                    let l:match_id = matchadd(l:hl_group, '\%'.l:lnum.'l\%'.(l:start+1).'c'.l:code)
                    call add(g:specialcolor_csscolor_matchid, l:match_id)
                endif
            endwhile
        endfor

        call setpos('.', l:currpos)
    endfunction

    " --------------------------------------------------
    " specialcolor#CsscolorCalcFg
    " --------------------------------------------------
    function! specialcolor#CsscolorCalcFg(hex) abort
        let l:r = str2nr(a:hex[1:2], 16)
        let l:g = str2nr(a:hex[3:4], 16)
        let l:b = str2nr(a:hex[5:6], 16)
        let l:brightness = (0.299 * l:r + 0.587 * l:g + 0.114 * l:b) / 255
        return l:brightness > 0.5 ? 'Black' : 'White'
    endfunction

    " --------------------------------------------------
    " specialcolor#CsscolorHexFix
    " --------------------------------------------------
    function! specialcolor#CsscolorHexFix(hex) abort
        if a:hex =~? '^#[0-9a-f]\{3}$'
            let l:r = repeat(a:hex[1], 2)
            let l:g = repeat(a:hex[2], 2)
            let l:b = repeat(a:hex[3], 2)
            return '#'.l:r.l:g.l:b
        elseif a:hex =~? '^#[0-9a-f]\{6}$'
            return a:hex
        endif
        return ''
    endfunction

    " --------------------------------------------------
    " specialcolor#CsscolorHexTerm
    " --------------------------------------------------
    function! specialcolor#CsscolorHexTerm(hex) abort
        if a:hex =~? '^#[0-9a-f]\{3}$'
            let l:color_hex = specialcolor#CsscolorHexFix(a:hex)
        else
            let l:color_hex = a:hex
        endif
        let l:color_map = {
            \ '#000000': '0',  '#800000': '1',  '#008000': '2',  '#808000': '3',
            \ '#000080': '4',  '#800080': '5',  '#008080': '6',  '#c0c0c0': '7',
            \ '#808080': '8',  '#ff0000': '9',  '#00ff00': '10', '#ffff00': '11',
            \ '#0000ff': '12', '#ff00ff': '13', '#00ffff': '14', '#ffffff': '15'
            \ }
        return get(l:color_map, tolower(l:color_hex), 'NONE')
    endfunction

    " --------------------------------------------------
    " specialcolor#CsscolorRgbFix
    " --------------------------------------------------
    function! specialcolor#CsscolorRgbFix(rgb) abort
        let l:color_rgb = matchstr(a:rgb, 'rgb(\zs.*\ze)')
        let l:color_split = split(l:color_rgb, '\s*,\s*')
        if len(l:color_split) != 3 | return '' | endif
        let l:r = float2nr(str2float(l:color_split[0]) * 255 / (l:color_split[0] =~ '%' ? 100.0 : 255.0))
        let l:g = float2nr(str2float(l:color_split[1]) * 255 / (l:color_split[1] =~ '%' ? 100.0 : 255.0))
        let l:b = float2nr(str2float(l:color_split[2]) * 255 / (l:color_split[2] =~ '%' ? 100.0 : 255.0))
        return printf('#%02x%02x%02x', l:r, l:g, l:b)
    endfunction

    " --------------------------------------------------
    " specialcolor#CsscolorRgbaFix
    " --------------------------------------------------
    function! specialcolor#CsscolorRgbaFix(rgba) abort
        let l:color_rgba = matchstr(a:rgba, 'rgba(\zs.*\ze)')
        let l:color_split = split(l:color_rgba, '\s*,\s*')
        if len(l:color_split) != 4 | return '' | endif
        let l:r = float2nr(str2float(l:color_split[0]) * 255 / (l:color_split[0] =~ '%' ? 100.0 : 255.0))
        let l:g = float2nr(str2float(l:color_split[1]) * 255 / (l:color_split[1] =~ '%' ? 100.0 : 255.0))
        let l:b = float2nr(str2float(l:color_split[2]) * 255 / (l:color_split[2] =~ '%' ? 100.0 : 255.0))
        return printf('#%02x%02x%02x', l:r, l:g, l:b)
    endfunction

    " --------------------------------------------------
    " specialcolor_cmd_csscolor_bas
    " --------------------------------------------------
    augroup specialcolor_cmd_csscolor_bas
        autocmd!
        autocmd CursorMoved,CursorMovedI * call specialcolor#CsscolorSetColor()
        autocmd BufWritePost * call specialcolor#CsscolorSetColor()
        autocmd BufEnter * call specialcolor#CsscolorSetColor()
    augroup END

endif

" ============================================================================
" Other
" ============================================================================
let &cpoptions = s:save_cpo
unlet s:save_cpo

