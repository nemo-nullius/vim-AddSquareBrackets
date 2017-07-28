function GetCharUnderCursor()
    " Get the character under cursor, including Chinese characters which
    " occupies 3 bytes in UTF-8.
    return matchstr(getline('.'), '\%' . col('.') . 'c.')
endfunction

function GetCharInSameLine(pos)
    " Get the character in the same line, including Chinese characters which
    " occupies 3 bytes in UTF-8.
    let l:char_line = line('.')
    let l:char_col = col('.')
    if a:pos > 0
        execute "normal! ". a:pos . "l"
    elseif a:pos < 0
        execute "normal! ". -a:pos . "h"
    endif
    let l:result = matchstr(getline('.'), '\%' . col('.') . 'c.')
    call cursor(l:char_line, l:char_col) "let cursor go back to the original place
    return l:result
endfunction

function CheckEndOfLine()
    " Check whether the char under cursor is at the end of its line.
    " Another way of doing this is: if len(getline('.')) ==# col('.')
    " but this will not work for three bytes characters, which requires
    " if len(getline('.')) ==# col('.') + 2
    let l:char_line = line('.')
    let l:char_col = col('.')
    normal! l
    if l:char_col ==# col('.')
        " call cursor(l:char_line, l:char_col)
        return 1
    else
        " call cursor(l:char_line, l:char_col)
        normal! h
        return 0
endfunction

function SetMutipleSquareBrackets()
    " To insert a pair of square brackets around a certain char. like [我].
    " And when there has been a square brackets around a previous, it will
    " automatically combine with the previous brackets, like [我们]
    if GetCharUnderCursor() ==# '[' || GetCharUnderCursor() ==# ']'
        return 'Error'
    endif
    if col('.') ==# 1 " At the begiining
        normal! l
        if GetCharUnderCursor() ==# '['
            normal! xhi[
            normal! l
            return -1
        endif
        normal! h
        normal! i[
        normal! la]
        normal! h
        return -2
    endif
    "if len(getline('.')) ==# col('.') + 2 " At the end, and the last char must be a 3-byte-character
    if CheckEndOfLine()
        normal! h
        if GetCharUnderCursor() ==# ']'
            normal! xa]
            normal! h
            return -3
        endif
        normal! l
        normal! i[
        normal! la]
        normal! h
        return -4
    endif
    if GetCharInSameLine(-1) ==# ']' && GetCharInSameLine(1) ==# '[' " [X]Y[Z]
        normal! hxlxh
        return -5
    endif
    normal! h
    if GetCharUnderCursor() ==# ']' " [X]Y
        " This line alone 'normal! xa]\<Esc>h' will not work as expected. For
        " this normal command considers sth strange with insert mode. There
        " will be an <Esc> automatically after the end of the normal command. 
        " See 'help normal' and 'help startinstart' for detail.
        " So we must use a new normal command after the insert.
        normal! xa]
        normal! h
        return 0
    endif
    normal! ll
    if GetCharUnderCursor() ==# '[' " WX[Y]
        normal! xhi[
        normal! l
        return 1
    endif
    " Back to the original place
    normal! h
    normal! i[
    normal! la]
    normal! h
    return 2
endfunction

function SetMutipleSquareBrackets2() " An advanced version: In some cases, after the insertation of [X] , the cursor will move to the next/last char, rather than stay on the original char.
    " To insert a pair of square brackets around a certain char. like [我].
    " And when there has been a square brackets around a previous, it will
    " automatically combine with the previous brackets, like [我们]
    if GetCharUnderCursor() ==# '[' || GetCharUnderCursor() ==# ']'
        return 'Error'
    endif
    if col('.') ==# 1 " At the begiining
        normal! l
        if GetCharUnderCursor() ==# '['
            normal! xhi[
            normal! l
            return -1
        endif
        normal! h
        normal! i[
        normal! la]
        normal! l
        return -2
    endif
    "if len(getline('.')) ==# col('.') + 2 " At the end, and the last char must be a 3-byte-character
    if CheckEndOfLine()
        normal! h
        if GetCharUnderCursor() ==# ']'
            normal! xa]
            normal! l
            return -3
        endif
        normal! l
        normal! i[
        normal! la]
        normal! l
        return -4
    endif
    if GetCharInSameLine(-1) ==# ']' && GetCharInSameLine(1) ==# '[' " [X]Y[Z]
        normal! hxlxh
        return -5
    endif
    normal! h
    if GetCharUnderCursor() ==# ']' " [X]Y
        " This line alone 'normal! xa]\<Esc>h' will not work as expected. For
        " this normal command considers sth strange with insert mode. There
        " will be an <Esc> automatically after the end of the normal command. 
        " See 'help normal' and 'help startinstart' for detail.
        " So we must use a new normal command after the insert.
        normal! xa]
        normal! l
        return 0
    endif
    normal! ll
    if GetCharUnderCursor() ==# '[' " WX[Y]
        normal! xhi[
        normal! h
        return 1
    endif
    " Back to the original place
    normal! h
    normal! i[
    normal! la]
    normal! l
    return 2
endfunction


function DeleteSquareBracket()
    let l:i = 0
    let l:result = 0
    while l:i < 5 " Delete ]  Five characters will be in a pair of brackets at most.
        let l:i += 1
        if GetCharInSameLine(l:i) ==# '[' " If there is a [ before ], it means that in this search process, there is no [].
            break
        endif
        if GetCharInSameLine(l:i) ==# ']'
            execute 'normal! '.l:i.'l'
            if CheckEndOfLine() " If ] is at the end of the line
                if i ==# 1
                    execute 'normal! x'
                else
                    execute 'normal! x'.(l:i-1).'h'
                endif
            else " If ] is not at the end of the line
                execute 'normal! x'.l:i.'h'
            endif
            let l:result += 1
            break
        endif
    endwhile

    if l:result ==# 0 " No ] is deleted.
        return 0 " End this function
    endif

    let l:i = 0
    while l:i < 5 " Delete [
        let l:i += 1
        if GetCharInSameLine(-l:i) ==# ']' " Actually this line is not necessary, for [] appear in a pair.
        " But in order to make this plugin robust, I still put this line here.
            return 'Error'
        endif
        if GetCharInSameLine(-l:i) ==# '['
            execute 'normal! '.l:i.'h'
            if l:i ==# 1 "0l goes back to the beginning of this line
                execute 'normal! x'
            else
                execute 'normal! x'.(l:i-1).'l'
            endif
            let l:result += 1
            break
        endif
    endwhile
    return l:result
endfunction

function DeleteSquareBracket2() " An advanced version. Clearer, Correcter, Easier.
    " Detect the pair of brackets first
    let l:charpos_line = line('.')
    let l:charpos_col = col('.')
    let l:result = 0

    let l:i = 0
    while i <= 5 " Check ] on the right side
        let l:i += 1
        if GetCharInSameLine(l:i) ==# '['
            return 1 " Not in a pair of brackets. End this function.
        endif
        if GetCharInSameLine(l:i) ==# ']'
            let l:bbracket = l:i
            let l:result += 1
            break
        endif
    endwhile

    let l:i = 0
    while i <=5 " Check [ on the lift side
        let l:i += 1
        if GetCharInSameLine(-l:i) ==# ']'
            return 1 " Not in a pair of brackets. End this function.
        endif
        if GetCharInSameLine(-l:i) ==# '['
            let l:fbracket = l:i
            let l:result += 1
            break
        endif
    endwhile

    if l:result ==# 2 " There are both ] on the right side and [ on the left side.
        execute 'normal! '.l:bbracket.'lx'
        call cursor(l:charpos_line, l:charpos_col)
        execute 'normal! '.l:fbracket.'hx'
        call cursor(l:charpos_line, l:charpos_col-1)
        return 2
    endif

    return 0
endfunction

function GotoNextFbracket() " This function is used to goto next （ (in Chinese)
    let l:o_char_line = line('.') " Record the position of the original place
    let l:o_char_col = col('.')
    " Goto get the position of the char in the end.
    normal! $
    let l:endpos_col = col('.') 
    call cursor(l:o_char_line, o_char_col) " After get the position of the char in the end, go back to the original place.

    let l:char_col = col('.') " Record the position of the present char.
    while l:char_col < l:endpos_col " DON'T use <=, for if the cursor is at the end, although normal l is used, the l:char_col will not be added!
        if GetCharUnderCursor() ==# '（'
            normal! l
            return 1 " End this function
        endif
        normal! l
        let l:char_col = col('.')
        "echo l:char_col
    endwhile
    call cursor(l:o_char_line, o_char_col) " If no （ is found, go back to the original place.
    return 0
endfunction
    
function GotoLastFbracket() " This function is used to goto last （ if exists
    let l:o_char_line = line('.') " Record the position of the original place
    let l:o_char_col = col('.')
    
    let l:char_col = col('.') " Record the position of the present char.
    while l:char_col > 1 " DON'T use >=, for if the cursor is at the beginning, although normal h is used, the l:char_col will not change!
        if GetCharUnderCursor() ==# '（'
            normal! l
            return 1 " End this function
        endif
        normal! h
        let l:char_col = col('.')
        "echo l:char_col
    endwhile
    call cursor(l:o_char_line, o_char_col) " If no （ is found, go back to the original place.
    return 0
endfunction
    


nnoremap <F2> :echom SetMutipleSquareBrackets2()<CR>
nnoremap <F4> :echom DeleteSquareBracket2()<CR>
nnoremap <silent> <F3> i[<Esc>la]<Esc>h
nnoremap <c-l> :echom GotoNextFbracket()<CR>
"nnoremap <c-h> :echom GotoLastFbracket()<CR>
verbose nnoremap <c-h> :echom GotoLastFbracket()<CR>
" Actually this <c-h> is mapped to <c-s-h>. Why?
