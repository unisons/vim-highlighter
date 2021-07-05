" Vim Highlighter: Vim easy words highlighter
" Author: Azabiong
" License: MIT
" Source: https://github.com/azabiong/vim-highlighter
" Version: 1.18

scriptencoding utf-8
if exists("s:Version")
  finish
endif
let s:cpo_save = &cpo
set cpo&vim

if !exists("g:HiOneTimeWait")
  let g:HiOneTimeWait = 260
endif
if !exists("g:HiFollowWait")
  let g:HiFollowWait = 320
endif
if !exists('g:HiFindTool')
  let g:HiFindTool = ''
endif
if !exists('g:HiFindHistory')
  let g:HiFindHistory = 5
endif
let g:HiFindLines = 0

let s:Version   = '1.18'
let s:Keywords  = {'usr': expand('<sfile>:h:h').'/keywords/', 'plug': expand('<sfile>:h').'/keywords/', '.':[]}
let s:Find      = {'tool':'', 'opt':[], 'exp':'', 'file':[], 'line':'', 'err':0,
                  \'type':'', 'options':{}, 'hi_exp':[], 'hi':[], 'hi_err':'', 'hi_tag':0}
let s:FindList  = {'name':' Find *', 'height':8, 'buf':0, 'pos':0, 'lines':0, 'select':0, 'edit':0,
                  \'logs':[{'list':[], 'status':'', 'hi':[]}], 'index':0, 'log':''}
let s:FindOpts  = ['--literal', '_li', '--fixed-strings', '_li', '--smart-case', '_sc', '--ignore-case',  '_ic',
                  \'--word-regexp', '_wr', '--regexp', '_re']
let s:FindTools = ['rg --color=never --no-heading --column --smart-case',
                  \'ag --nocolor --noheading --column --nobreak',
                  \'ack --nocolor --noheading --column --smart-case',
                  \'sift --no-color --line-number --column --binary-skip --git --smart-case',
                  \'ggrep -EnrI--exclude-dir=.git',
                  \'git grep -EnrI --no-color --column',
                  \'grep -EnrI--exclude-dir=.git']
const s:FL = s:FindList

function s:Load()
  if !exists('s:Check')
    let s:Check = 0
  endif
  if s:Check < 256
    if has('gui_running') || (has('termguicolors') && &termguicolors) || &t_Co >= 256
      let s:Check = 256
    elseif s:Check == 0
      echo "\n Highlighter:\n\n"
          \" It seems that current color mode is lower than 256 colors:\n"
          \"     &t_Co=".&t_Co."\n\n"
          \" To enable 256 colors, please try:\n"
          \"    :set t_Co=256 \n\n"
      let s:Check = &t_Co + 1
      return
    endif
  endif
  if s:Check >= 256
    let s:Colors = [
    \ ['HiOneTime', 'ctermfg=234 ctermbg=152 cterm=none guifg=#001727 guibg=#afd9d9 gui=none'],
    \ ['HiFollow',  'ctermfg=234 ctermbg=151 cterm=none guifg=#002f00 guibg=#afdfaf gui=none'],
    \ ['HiFind',    'ctermfg=52  ctermbg=187 cterm=none guifg=#471707 guibg=#e3d3b7 gui=none'],
    \ ['HiColor1',  'ctermfg=17  ctermbg=112 cterm=none guifg=#001767 guibg=#8fd757 gui=none'],
    \ ['HiColor2',  'ctermfg=52  ctermbg=221 cterm=none guifg=#570000 guibg=#fcd757 gui=none'],
    \ ['HiColor3',  'ctermfg=225 ctermbg=90  cterm=none guifg=#ffdff7 guibg=#8f2f8f gui=none'],
    \ ['HiColor4',  'ctermfg=195 ctermbg=68  cterm=none guifg=#dffcfc guibg=#5783c7 gui=none'],
    \ ['HiColor5',  'ctermfg=19  ctermbg=189 cterm=bold guifg=#0000af guibg=#d7d7fc gui=bold'],
    \ ['HiColor6',  'ctermfg=89  ctermbg=225 cterm=bold guifg=#87005f guibg=#fcd7fc gui=bold'],
    \ ['HiColor7',  'ctermfg=52  ctermbg=180 cterm=bold guifg=#570000 guibg=#dfb787 gui=bold'],
    \ ['HiColor8',  'ctermfg=223 ctermbg=130 cterm=bold guifg=#fcd7a7 guibg=#af5f17 gui=bold'],
    \ ['HiColor9',  'ctermfg=230 ctermbg=242 cterm=bold guifg=#f7f7d7 guibg=#676767 gui=bold'],
    \ ['HiColor10', 'ctermfg=194 ctermbg=23  cterm=none guifg=#cff3f3 guibg=#276c37 gui=none'],
    \ ['HiColor11', 'ctermfg=22  ctermbg=194 cterm=bold guifg=#004f00 guibg=#d7f7df gui=bold'],
    \ ['HiColor12', 'ctermfg=52  ctermbg=229 cterm=none guifg=#371700 guibg=#f7f7a7 gui=none'],
    \ ['HiColor13', 'ctermfg=53  ctermbg=219 cterm=none guifg=#570027 guibg=#fcb7fc gui=none'],
    \ ['HiColor14', 'ctermfg=17  ctermbg=153 cterm=none guifg=#000057 guibg=#afd7fc gui=none'],
    \ ]
  else
    let s:Colors = [
    \ ['HiOneTime', 'ctermfg=darkBlue ctermbg=lightCyan' ],
    \ ['HiFollow',  'ctermfg=darkBlue ctermbg=lightGreen'],
    \ ['HiFind',    'ctermfg=yellow ctermbg=darkGray'    ],
    \ ['HiColor1',  'ctermfg=white ctermbg=darkGreen'    ],
    \ ['HiColor2',  'ctermfg=white ctermbg=darkCyan'     ],
    \ ['HiColor3',  'ctermfg=white ctermbg=darkMagenta'  ],
    \ ['HiColor4',  'ctermfg=white ctermbg=darkYellow'   ],
    \ ['HiColor5',  'ctermfg=black ctermbg=lightYellow'  ],
    \ ]
  endif
  let s:Color = 'HiColor'
  let s:SchemeRange = 64
  let s:Wait = [g:HiOneTimeWait, g:HiFollowWait]
  let s:WaitRange = [[0, 320], [260, 520]]
  call s:SetColors(0)

  aug Highlighter
    au!
    au BufEnter       * call <SID>BufEnter()
    au BufLeave       * call <SID>BufLeave()
    au BufHidden      * call <SID>BufHidden()
    au WinEnter       * call <SID>WinEnter()
    au WinLeave       * call <SID>WinLeave()
    au BufWinEnter    * call <SID>BufWinEnter()
    au ColorSchemePre * call <SID>ColorSchemePre()
    au ColorScheme    * call <SID>ColorScheme()
  aug END
  return 1
endfunction

function s:SetColors(default)
  for l:c in s:Colors
    if a:default || empty(s:GetColor(l:c[0]))
      exe 'hi' l:c[0].' '.l:c[1]
    endif
  endfor
endfunction

function s:GetColor(color)
  return hlexists(a:color) ? matchstr(execute('hi '.a:color), '\(cterm\|gui\).*') : ''
endfunction

function s:SetHighlight(cmd, mode, num)
  if s:CheckRepeat(60) | return | endif

  if !exists("w:HiColor")
    let w:HiColor = 0
  endif
  let l:match = getmatches()

  if a:cmd == '--'
    for l:m in l:match
      if match(l:m['group'], s:Color) == 0
        call matchdelete(l:m['id'])
      endif
    endfor
    let w:HiColor = 0
    return
  elseif a:cmd == '+'
    let l:color = s:GetNextColor(a:num)
  else
    let l:color = 0
  endif

  if a:mode == 'n'
    let l:word = expand('<cword>')
  else
    let l:visual = trim(s:GetVisualLine())
    let l:word = l:visual
  endif
  if empty(l:word)
    if !l:color | call s:SetMode('-', '') | endif
    return
  endif
  let l:word = escape(l:word, '\')
  if a:mode == 'n'
    let l:word = '\V\<'.l:word.'\>'
  else
    let l:word = '\V'.l:word
  endif

  " hlsearch overlap
  let l:case = (&ic || stridx(@/, '\c') != -1) ? '\c' : ''
  let l:search = match(@/, l:word.l:case) != -1

  let l:deleted = s:DeleteMatch(l:match, '==', l:word)
  if l:color
    if a:mode == 'n' && s:GetMode(l:word)
      call s:SetMode('>', l:word)
    else
      let w:HiColor = l:color
      call matchadd(s:Color.l:color, l:word, 0)
      let s:Search = l:search
    endif
  else
    if !l:deleted
      if a:mode == 'n'
        let l:deleted = s:DeleteMatch(l:match, '≈n', s:GetStringPart())
      else
        let l:deleted = s:DeleteMatch(l:match, '≈x', l:visual)
      endif
    endif
    if !l:deleted
      let s:Search = (s:SetMode('.', l:word) == '1') && l:search
    endif
  endif
endfunction

function s:CheckRepeat(interval)
  if !exists("s:InputTime")
    let s:InputTime = reltime()
    return
  endif
  let l:dt = reltimefloat(reltime(s:InputTime)) * 1000
  let s:InputTime = reltime()
  return l:dt < a:interval
endfunction

function s:GetNextColor(num)
  let l:next = a:num ? a:num : (v:count ? v:count : w:HiColor+1)
  return hlexists(s:Color.l:next) ? l:next : 1
endfunction

function s:GetVisualLine()
  let [l:top, l:left] = getpos("'<")[1:2]
  let [l:bottom, l:right] = getpos("'>")[1:2]
  if l:top != l:bottom | let l:right = -1 | endif
  if l:left == l:right | return | endif
  if l:right > 0
    let l:right -= &selection == 'inclusive' ? 1 : 2
  endif
  let l:line = getline(l:top)
  return l:line[l:left-1 : l:right]
endfunction

function s:DeleteMatch(match, op, part)
  let l:i = len(a:match)
  while l:i > 0
    let l:i -= 1
    let l:m = a:match[l:i]
    if match(l:m.group, s:Color.'\d\{,2}\>') == 0
      let l:match = 0
      if a:op == '=='
        let l:match = a:part ==# l:m.pattern
      elseif (a:op == '≈n')
        if l:m.pattern[2:3] != '\<'
          let l:match = match(a:part.word, l:m.pattern) != -1
          if !l:match && stridx(l:m.pattern, ' ') != -1
            let l:match = match(a:part.line, l:m.pattern) != -1
          endif
        endif
      elseif a:op == '≈x'
        let l:match = match(a:part, l:m.pattern) != -1
      endif
      if l:match
        return matchdelete(l:m.id) + 1
      endif
    endif
  endwhile
endfunction

function s:GetStringPart()
  let l:line = getline('.')
  let l:col = col('.')
  let l:low = max([l:col-256, 0])
  let l:left = strpart(l:line, l:low, l:col - l:low)
  let l:right = strpart(l:line, l:col, l:col + 256)
  let l:word = matchstr(l:left, '\zs\S\+$')
  let l:word .= matchstr(l:right, '^\S\+')
  return {'word':l:word, 'line': l:left.l:right}
endfunction

function s:GetMode(word)
  return !v:count && exists("w:HiMode") &&
       \ !w:HiMode['>'] && w:HiMode['p'] == getpos('.') && w:HiMode['w'] ==# a:word
endfunction

" s:SetMode(cmd) actions
"     |       |     !>     |     >    |
" cmd | !mode | !same same | !key key |  1:on, 0:off
"  .  |   1   |   =     0  |   0   >  |  =:update
"  >  |   >   |   >     >  |   >   >  |  >:follow
"  -  |   0   |   0     0  |   0   0  |
function s:SetMode(cmd, word)
  if a:cmd == '.'
    if !exists("w:HiMode")
      let l:word = a:word
      let l:op = '1'
    elseif !w:HiMode['>']
      let l:word = empty(a:word) ? s:GetCurrentWord('*') : a:word
      let l:op = (w:HiMode['w'] ==# l:word) ? '0' : '='
    else
      let l:word = s:GetCurrentWord('k')
      let l:op = (empty(w:HiMode['m']) || empty(l:word)) ? '0' : '>'
    endif
  elseif a:cmd == '>'
    let l:word = empty(a:word) ? s:GetCurrentWord('*') : a:word
    let l:op = '>'
  else
    let l:op = '0'
  endif

  if stridx('1=>', l:op) != -1
    call s:LinkCursorEvent(l:word)
    let w:HiMode['p'] = getpos('.')
    if l:op == '>'
      call s:GetKeywords()
      let w:HiMode['>'] = 1
      let w:HiMode['_'] = s:Wait[1]
      call s:UpdateHiWord(0)
    elseif l:op == '='
      call timer_stop(w:HiMode['t'])
      let w:HiMode['t'] = 0
    endif
  elseif l:op == '0'
    call s:UnlinkCursorEvent(1)
  endif
  return l:op
endfunction

" symbols: follow('>'), wait('_'), pos, timer, reltime, match, word
function s:LinkCursorEvent(word)
  let l:event = exists("#HiEventCursor")
  if !exists("w:HiMode")
    let w:HiMode = {'>':0, '_':s:Wait[0], 'p':[], 't':0, 'r':[], 'm':'', 'w':a:word}
    call s:UpdateWait()
  else
    let w:HiMode['w'] = a:word
  endif
  call s:UpdateHiWord(0)
  if !l:event
    aug HiEventCursor
      au!
      au InsertEnter * call <SID>InsertEnter()
      au InsertLeave * call <SID>InsertLeave()
      au CursorMoved * call <SID>FollowCursor()
    aug END
  endif
endfunction

function s:UnlinkCursorEvent(force)
  if exists("#HiEventCursor")
    au!  HiEventCursor
    aug! HiEventCursor
    if exists("w:HiMode")
      call s:EraseHiWord()
      if a:force || !w:HiMode['>']
        unlet w:HiMode
      endif
    endif
  endif
endfunction

function s:UpdateWait()
  let l:wait = [g:HiOneTimeWait, g:HiFollowWait]
  if l:wait != s:Wait
    let s:Wait[0] = min([max([l:wait[0], s:WaitRange[0][0]]), s:WaitRange[0][1]])
    let s:Wait[1] = min([max([l:wait[1], s:WaitRange[1][0]]), s:WaitRange[1][1]])
    let [g:HiOneTimeWait, g:HiFollowWait] = s:Wait
    let w:HiMode['_'] = s:Wait[0]
  endif
endfunction

function s:EraseHiWord()
  if !empty(w:HiMode['m'])
    if w:HiMode['m'] == '<1>'
      call s:SetOneTimeWin('')
    else
      call matchdelete(w:HiMode['m'])
    endif
    let w:HiMode['m'] = ''
    let w:HiMode['w'] = ''
  endif
endfunction

function s:SetHiWord(word)
  if empty(a:word) | return | endif
  if w:HiMode['>']
    let w:HiMode['m'] = matchadd('HiFollow', a:word, -1)
  else
    let w:HiMode['m'] = '<1>'
    call s:SetOneTimeWin(a:word)
  endif
  let w:HiMode['w'] = a:word
endfunction

function s:GetKeywords()
  let l:ft = !empty(&filetype) ? split(&filetype, '\.')[0] : ''
  if !exists("s:Keywords['".l:ft."']")
    let s:Keywords[l:ft] = []
    let l:list = s:Keywords[l:ft]
    for l:file in [s:Keywords.plug.l:ft, s:Keywords.usr.l:ft]
      if filereadable(l:file)
        for l:line in readfile(l:file)
          if l:line[0] == '#' | continue | endif
          let l:list += split(l:line)
        endfor
      endif
    endfor
    call uniq(sort(l:list))
  endif
  let s:Keywords['.'] = s:Keywords[l:ft]
endfunction

" op:  *:any  #:filter  k:keyword
function s:GetCurrentWord(op)
  if match(getline('.')[col('.')-1], '\k') != -1
    let l:word = expand('<cword>')
    let l:keyword = index(s:Keywords['.'], l:word) != -1
    if(a:op == '*') || (a:op == '#' && !l:keyword) || (a:op == 'k' && l:keyword)
      return '\V\<'.l:word.'\>'
    endif
  endif
endfunction

function s:FollowCursor(...)
  if !exists("w:HiMode") | return | endif
  if w:HiMode['t']
    let w:HiMode['r'] = reltime()
  else
    let l:wait = a:0 ? a:1 : w:HiMode['_']
    let w:HiMode['t'] = timer_start(l:wait, function('s:UpdateHiWord'))
    let w:HiMode['r'] = []
  endif
endfunction

function s:UpdateHiWord(tid)
  if !exists("w:HiMode") | return | endif
  if !a:tid
    let l:word = empty(w:HiMode['w']) ? s:GetCurrentWord('#') : w:HiMode['w']
    let w:HiMode['t'] = 0
  else
    if !empty(w:HiMode['r'])
      let l:wait = float2nr(reltimefloat(reltime(w:HiMode['r'])) * 1000)
      let l:wait = max([0, w:HiMode['_'] - l:wait])
      let w:HiMode['t'] = 0
      call s:FollowCursor(l:wait)
      return
    endif
    if w:HiMode['>']
      let w:HiMode['t'] = 0
      let l:word = s:GetCurrentWord('#')
      if  l:word ==# w:HiMode['w'] | return | endif
    else
      if w:HiMode['p'] == getpos('.') && mode() =='n' " visual selection
        let w:HiMode['t'] = 0
      else
        call s:UnlinkCursorEvent(1)
      endif
      return
    endif
  endif
  call s:EraseHiWord()
  call s:SetHiWord(l:word)
endfunction

function s:InsertEnter()
  if !exists("w:HiMode") | return | endif
  if w:HiMode['>']
    call s:EraseHiWord()
  else
    call s:FollowCursor()
  endif
endfunction

function s:InsertLeave()
  if !exists("w:HiMode") || !w:HiMode['>'] | return | endif
  call s:LinkCursorEvent('')
endfunction

function s:SetOneTimeWin(exp)
  let l:win = winnr()
  noa windo call <SID>SetOneTime(a:exp)
  noa exe l:win." wincmd w"
endfunction

function s:SetOneTime(exp)
  if empty(a:exp)
    if exists('w:HiOneTime')
      call matchdelete(w:HiOneTime)
      unlet w:HiOneTime
    endif
  else
    let w:HiOneTime = matchadd('HiOneTime', a:exp)
  endif
endfunction

function s:SetHiFindWin(on, buf)
  let l:win = winnr()
  noa windo call <SID>SetHiFind(a:on, a:buf)
  noa exe l:win." wincmd w"
endfunction

function s:SetHiFind(on, buf)
  if exists('w:HiFind')
    if a:on && w:HiFind.tag == s:Find.hi_tag | return | endif
    for m in w:HiFind.id
      call matchdelete(m)
    endfor
    unlet w:HiFind
  endif
  if a:on && (empty(&buftype) || bufnr() == a:buf)
    let w:HiFind = {'tag':s:Find.hi_tag, 'id':[]}
    for h in s:Find.hi
      call add(w:HiFind.id, matchadd('HiFind', h))
    endfor
  endif
endfunction

function s:Find(mode)
  if !s:FindTool() | return | endif

  let l:visual = (a:mode == 'x') ? '"'.escape(s:GetVisualLine(), '$^*()-+[]{}\|.?"').'"' : ''
  call inputsave()
  let l:input = input('  Find  ', l:visual)
  call inputrestore()
  if !s:FindArgs(l:input) | return | endif

  let l:cmd = [s:Find.tool] + s:Find.opt
  if !empty(s:Find.exp)
    let l:cmd += [s:Find.exp]
  endif
  let l:cmd += s:Find.file
  call s:FindStop(0)
  call s:FindStart(l:input)
  if exists('*job_start')
    let s:Find.job = job_start(l:cmd, {
        \ 'in_io': 'null',
        \ 'out_cb':  function('s:FindOut'),
        \ 'err_cb':  function('s:FindErr'),
        \ 'close_cb':function('s:FindClose'),
        \ })
  elseif exists('*jobstart')
    let s:Find.job = jobstart(l:cmd, {
        \ 'on_stdout': function('s:FindStdOut'),
        \ 'on_stderr': function('s:FindStdOut'),
        \ 'on_exit':   function('s:FindExit'),
        \ })
  endif
endfunction

function s:FindTool()
  let l:list = !empty(g:HiFindTool) ? [g:HiFindTool] : s:FindTools
  let l:tool = ''
  for l:line in l:list
    let l:cmd = matchstr(l:line, '\v\S+')
    if !empty(l:cmd) && executable(l:cmd)
      let l:tool = l:cmd
      if empty(g:HiFindTool) | let g:HiFindTool = l:line | endif
      break
    endif
  endfor
  if empty(l:tool)
    echo " No executable search tool, HiFindTool='".g:HiFindTool."'"
    return
  elseif !exists('*job_start') && !exists('*jobstart')
    echo " channel - feature not found "
    return
  endif

  if s:Find.tool !=# l:tool
    let s:Find.tool = l:tool
    let s:Find.options = {'single':[], 'single!':[], 'with_value':[], 'with_value!':[], '_':[]}
    let s:Find.type = (l:tool =~ 'grep$') ? 'grep' : l:tool
    let l:file = s:Keywords.plug.'_'.s:Find.type
    let l:type = '_'
    if filereadable(l:file)
      for l:line in readfile(l:file)
        if l:line[0] == '#'
          continue
        elseif index(['single:', 'single!:', 'with_value:', 'with_value!:'], l:line) != -1
          let l:type = l:line[:-2] | continue
        else
          let s:Find.options[l:type] += split(l:line)
        endif
      endfor
    endif
  endif
  return 1
endfunction

function s:FindArgs(arg)
  if match(a:arg, '\S') == -1
    call s:FindStatus('') | return
  endif
  let s:Find.opt = []
  let s:Find.exp = ''
  let s:Find.file = []
  let s:Find.hi_exp = []
  let s:Find.hi_err = ''
  let l:opt = s:FindOptions(a:arg)
  let l:exp = s:FindUnescape(l:opt.exp)
  if empty(l:opt._re)
    let s:Find.exp = l:exp.str
  elseif !empty(l:exp.str)
    call add(s:Find.file, l:exp.str)
  endif
  while !empty(l:exp.next)
    let l:exp = s:FindUnescape(l:exp.next)
    call add(s:Find.file, l:exp.str)
  endwhile
  if empty(s:Find.file) | let s:Find.file = ['.'] | endif
  call s:FindMatch(l:opt)
  return 1
endfunction

function s:FindOptions(arg)
  let l:opt = {'case':{'i':0, 'I':0, '_ic':0, 's':0, 'S':0, '_sc':0}, 'pos':32, 'nohi':0, 'exp':'',
              \'F':0, 'Q':0, '_li':0, 'w':0, '_wr':0, '_re':[]}
  let l:args = len(s:Find.tool)
  let l:args = g:HiFindTool[l:args+1:].' '.a:arg.' '
  let l:next = 0 | let l:key = ''
  let l:len = len(l:args)
  let i = 0
  if l:args =~ '^grep'
    call add(s:Find.opt, 'grep') | let i = 5
  endif
  while i < l:len
    let l:c = l:args[i]
    if empty(l:key)
      if     l:c == ' '
      elseif l:c == '-'
        if l:args[i:i+3] == '-- '
          call add(s:Find.opt, '--') | let i += 3 | break
        endif
        let l:key = l:c
      else
        if !l:next | break | endif
        if l:c == '='
          let l:c = l:args[i+1]
          let i += 1
        endif
        let l:quote = 0
        if stridx("\"'", l:c) != -1
          let l:pair = stridx(l:args, l:c, i+1)
          let l:value = l:args[i+1:l:pair-1]
          let l:quote = 2
        else
          let l:value = matchstr(l:args, '\v\S+', i)
        endif
        if !empty(l:value)
          call add(s:Find.opt, l:value)
          let i += len(l:value) + l:quote
          if l:next == 2
            call add(l:opt._re, l:value)
          endif
        endif
        let l:next = 0 | let l:key = ''
      endif
    elseif stridx("=\ \"'", l:c) != -1
      call add(s:Find.opt, l:key)
      let l:next = s:FindFlag(l:opt, l:key)
      let l:key = ''
      continue
    else
      let l:key .= l:c
    endif
    let i += 1
  endwhile
  let l:opt.exp = l:args[i:-2]

  " --literal --fixed-strings
  let l:type = s:Find.type
  let l:opt._li += (l:opt.F && index(['ag','rg','grep', 'git'], l:type) != -1)
                \+ (l:opt.Q && index(['ack','sift'], l:type) != -1)
  if (s:Find.type == 'grep') && l:opt._li
    call s:FindAdjust('-E', '--extended-regexp')
  endif
  " --smart-case --ignore-case
  let l:case = l:opt.case
  let l:case._ic = max([l:case._ic, l:case.i])
  if  l:type == 'ag'
    let l:case._sc += 1
  endif
  if index(['ag', 'rg', 'ack'], l:type) != -1
    let l:case._sc = max([l:case._sc, l:case.S])
  elseif l:type == 'sift'
    let l:case._sc = max([l:case._sc, l:case.s])
  endif
  let l:o = max(l:case)
  if  l:o && l:o == l:case._sc
    if l:type == 'sift' && len(l:opt._re) > 1
      call s:FindAdjust('-s', '--smart-case')
    else
      let l:upper = l:opt._li ? '\v\u' : '\v^\u|[^\\]\u'
      let l:case._ic = match(s:Find.exp, l:upper) == -1
    endif
  elseif l:o != l:case._ic
    let l:case._ic = 0
  endif
  " --word-regexp
  let l:opt._wr = max([l:opt._wr, l:opt.w])
  return l:opt
endfunction

" return 'next' value -- 0:none, 1:with_value, 2:with_regexp
function s:FindFlag(opts, op)
  let l:options = ['single', 'single!', 'with_value', 'with_value!']
  let l:f = (a:op[1] == '-') ? a:op : a:op[:1]
  let l:known = 0
  let l:len = len(a:op)
  let l:inc = len(l:f) - 1
  let i = 1
  while i < l:len
    for l:opts in l:options
      if index(s:Find.options[l:opts], l:f) == -1 | continue | endif
      let a:opts.pos += 32 | let l:known = 1

      if l:inc > 1  " long options
        let l:o = index(s:FindOpts, l:f)
        if  l:o != -1
          let l:o = s:FindOpts[l:o+1]
          if l:o == '_re'
            return 2
          elseif index(['_ic', '_sc'], l:o)
            let a:opts.case[l:o] = a:opts.pos
          else
            let a:opts[l:o] = a:opts.pos
          endif
        endif
      else
        let l:f = l:f[1]
        if l:f ==# 'e'
          let l:p = i + l:inc
          if l:p == l:len | return 2 | endif
          call add(a:opts._re, a:op[l:p:])
          return 0
        elseif stridx("iIsS", l:f) != -1
          let a:opts.case[l:f] = a:opts.pos
        elseif stridx("FQw", l:f) != -1
          let a:opts[l:f] = a:opts.pos
        endif
      endif

      let a:opts.nohi += l:opts[-1:] == '!'
      if l:opts[0] == 'w'
        return i + l:inc == l:len
      endif
    endfor
    let a:opts.nohi += !l:known
    let l:known = 0
    let i += l:inc
    let l:f = '-'.a:op[i]
  endwhile
endfunction

function s:FindAdjust(short, long)
    let l:o = s:Find.opt
    for i in range(len(l:o))
      if (l:o[i] =~# '\v^-\w') && (stridx(l:o[i], a:short[1]) != -1)
        let l:o[i] = substitute(l:o[i], a:short[1], '', '')
        if  l:o[i] == '-' | call remove(l:o, i) | endif
        return
      elseif l:o[i] ==# a:long
        call remove(l:o, i)
        return
      endif
    endfor
endfunction

function s:FindUnescape(arg)
  let l:arg = trim(a:arg)
  let l:exp = {'str':'', 'next':''}
  let l:q = l:arg[0]
  if l:q == "'"
    let l:q = stridx(l:arg, l:q, 1)
    if  l:q == -1
      let l:q = stridx(l:arg, ' ', 1)
    endif
    if l:q == -1
      return {'str':l:arg[1:-1], 'next':''}
    else
      return {'str':l:arg[1:l:q-1], 'next':l:arg[l:q+1]}
    endif
  endif

  let l:len = len(l:arg)
  if  l:q != '"' | let l:q = '' | endif
  let i = len(l:q)
  while i < l:len
    let c = l:arg[i]
    if     c == '"'  | let i += 1    | break
    elseif c == ' '  | if empty(l:q) | break | endif
    elseif c == '\'
      let l:next = l:arg[i+1]
      if stridx(' "', l:next) != -1
        let c = l:next
      else
        let c .= l:next
      endif
      let i += 1
    endif
    let l:exp.str .= c
    let i += 1
  endwhile
  let l:exp.next = l:arg[i:]
  return l:exp
endfunction

function s:FindMatch(opt)
  if a:opt.nohi | return | endif
  if !empty(s:Find.exp)
    call add(a:opt._re, s:Find.exp)
  endif
  for l:exp in a:opt._re
    let l:exp = escape(l:exp, (a:opt._li ? '\' : '~@%&=<>'."'"))
    let [l:p, l:q] = ['', '']
    if a:opt.case._ic | let l:p = '\c' | endif
    if a:opt._wr
      let l:p .= '<' | let l:q = '>'
    else
      if l:exp[:1]  == '\b' | let l:exp = '<'.l:exp[2:]  | endif
      if l:exp[-2:] == '\b' | let l:exp = l:exp[:-3].'>' | endif
    endif
    let l:exp = (a:opt._li ? '\V' : '\v').l:p.l:exp.l:q
    call add(s:Find.hi_exp, l:exp)
  endfor
endfunction

function s:FindStatus(msg)
  call timer_start(0, {-> execute("echo '".a:msg."'", '')})
endfunction

function s:FindStart(arg)
  " buf variables: {Status}
  if !s:FL.buf
    let s:FL.buf = bufadd(s:FL.name)
    let s:FL.lines = 0
    let g:HiFindLines = 0
    call bufload(s:FL.buf)
    call s:FindOpen()

    setlocal buftype=nofile bh=hide noma noswapfile nofen ft=find
    let b:Status = ''
    let &l:statusline = '  Find | %<%{b:Status} %=%3.l / %L  '

    nn <silent><buffer><C-C>         :call <SID>FindStop(1)<CR>
    nn <silent><buffer>r             :call <SID>FindRotate()<CR>
    nn <silent><buffer>s             :call <SID>FindEdit('split')<CR>
    nn <silent><buffer><CR>          :call <SID>FindEdit('=')<CR>
    nn <silent><buffer><2-LeftMouse> :call <SID>FindEdit('=')<CR>

    " airline
    if exists('*airline#add_statusline_func')
      call airline#add_statusline_func('highlighter#Airline')
      call airline#add_inactive_statusline_func('highlighter#Airline')
      wincmd p | wincmd p
    endif
  endif

  if empty(s:FL.log)
    let s:FL.log = s:FL.logs[0]
  endif
  if !empty(s:FL.log.list)
    call add(s:FL.logs, {'list':[], 'status':[], 'hi':[]})
  endif
  let l:logs = len(s:FL.logs)
  let g:HiFindHistory = min([max([2, g:HiFindHistory]), 10])
  while l:logs > g:HiFindHistory
    call remove(s:FL.logs, 0)
    let l:logs -= 1
  endwhile
  let l:index = l:logs - 1
  let l:status = s:Find.tool.' '.join(s:Find.opt).'  '.s:Find.exp.'  '.join(s:Find.file)
  let s:FL.index = l:index
  let s:FL.log = s:FL.logs[l:index]
  let s:FL.log.status = l:status
  let s:FL.log.hi = []
  let s:Find.hi = []
  let s:Find.hi_tag += 1
  let s:Find.line = ''
  let s:Find.err = 0

  call s:FindSet([], '=')
  call s:FindOpen()
  call s:SetHiFind(0, 0)
  let w:HiFind = {'tag':s:Find.hi_tag, 'id':[]}
  let b:Status = l:status

  try
    for l:exp in s:Find.hi_exp
      let l:id = matchadd('HiFind', l:exp)
      call add(w:HiFind.id, l:id)
      call add(s:Find.hi, l:exp)
      call add(s:FL.log.hi, l:exp)
    endfor
  catch
    let s:Find.hi_err = v:exception
  endtry
  call s:FindStatus(" searching...")
endfunction

function s:FindOpen(...)
  if !s:FL.buf | return | endif
  let l:win = bufwinnr(s:FL.buf)
  if l:win == -1
    let l:pos = a:0 ? a:1: 0
    exe (l:pos ? 'vert ' : '').['bel', 'abo', 'bel'][l:pos].' sb'.s:FL.buf
    if  !l:pos | exe "resize ".min([s:FL.height, winheight(0)]) | endif
    let s:FL.pos = l:pos
  else
    exe l:win. " wincmd w"
  endif
  return l:win
endfunction

function s:FindStop(op)
  if     !exists('s:Find.job') | return
  elseif  exists('*job_stop')  | call job_stop(s:Find.job)
  elseif  exists('*jobstop')   | call jobstop(s:Find.job)
  endif
  call s:FindSet(['', '--- Search Interrupted ---', ''], '+')
  if a:op
    call s:FindOpen()
    exe "normal! G"
  endif
  let s:Find.err += 1
  sleep 250m
endfunction

function s:FindSet(lines, op, ...)
  call setbufvar(s:FL.buf, '&ma', 1)
  let l:err = 0
  let l:n = len(a:lines)
  if a:op == '='
    silent let l:err += deletebufline(s:FL.buf, 1, '$')
    let g:HiFindLines = 0
    let s:FL.lines = 0
    let s:FL.select = 0
    let s:FL.edit = 0
    if !empty(a:lines)
      let l:err += setbufline(s:FL.buf, 1, a:lines)
      if a:0
        call setbufvar(s:FL.buf, 'Status', a:1)
      endif
    endif
  elseif l:n
    for l:line in a:lines
      call add(s:FL.log.list, ' '.l:line)
    endfor
    if !s:FL.lines
      let l:err += setbufline(s:FL.buf, 1, s:FL.log.list[-l:n:])
    else
      let l:err += appendbufline(s:FL.buf, '$', s:FL.log.list[-l:n:])
    endif
  endif
  if l:err
    echoe " Find : Listing Error "
    let s:Find.err += 1
  else
    let s:FL.lines += l:n
    let g:HiFindLines = s:FL.lines
  endif
  call setbufvar(s:FL.buf, '&ma', 0)
endfunction

function s:FindOut(ch, msg)
  call s:FindSet([a:msg], '+')
endfunction

function s:FindErr(ch, msg)
  call s:FindSet([a:msg], '+')
  let s:Find.err += 1
endfunction

function s:FindClose(ch)
  unlet s:Find.job
  let l:s = s:FL.lines == 1 ? '' :  's'
  let l:msg = ' '.s:FL.lines.' item'.l:s.' found '
  if !s:FL.lines
    let s:Find.hi = []
  elseif s:Find.err || empty(s:FindSelect(1))
    let s:Find.hi = []
    let l:msg = ''
    call remove(s:FL.log.list, 0, -1)
  endif
  if !empty(s:Find.hi_err)
    let l:msg .= ' * '.s:Find.hi_err
  endif
  echo l:msg
  let l:win = winnr()
  noa wincmd p
  call s:SetHiFindWin(1, s:FL.buf)
  noa exe l:win." wincmd w"
endfunction

function s:FindStdOut(job, data, event)
  if a:data == [''] | let s:Find.line = '' | return | endif
  let s:Find.line .= a:data[0]
  call s:FindSet([s:Find.line], '+')
  call s:FindSet(a:data[1:-2], '+')
  let s:Find.line = a:data[-1]
  let s:Find.err += (a:event == 'stderr')
endfunction

function s:FindExit(job, code, type)
  call s:FindClose(0)
endfunction

function s:FindSelect(line)
  let l:line = getbufline(s:FL.buf, a:line)[0]
  if len(l:line) < 2 | return | endif

  let l:pos = 1
  let l:file = matchstr(l:line, '\v[^:]*', l:pos)
  if filereadable(l:file)
    call setbufvar(s:FL.buf, '&ma', 1)
    let l:pos += len(l:file) + 1
    let l:row = matchstr(l:line, '\v\d*', l:pos)
    let l:pos += len(l:row) + 1
    let l:col = matchstr(l:line, '\v\d*', l:pos)
    if s:FL.select
      let l:select = getbufline(s:FL.buf, s:FL.select)[0]
      call setbufline(s:FL.buf, s:FL.select, ' '.l:select[1:])
    endif
    call setbufline(s:FL.buf, a:line, '|'.l:line[1:])
    call setbufvar(s:FL.buf, '&ma', 0)
  else
    return
  endif
  let s:FL.select = a:line
  return {'name':l:file, 'row':l:row, 'col':l:col}
endfunction

function s:FindRotate()
  if winnr('$') == 1 | return | endif
  close
  call s:FindOpen((s:FL.pos + 1) % 3)
endfunction

function s:FindEdit(op)
  let l:file = s:FindSelect(line('.'))
  if empty(l:file) | return | endif

  let l:edit = 0
  if a:op == '=' && winnr('$') > 1
    let l:find = winnr()
    noa wincmd p
    let wins = extend([winnr()], range(winnr('$'),1, -1))
    for w in wins
      noa exe w. " wincmd w"
      if empty(&buftype)
        let l:edit = w | break
      endif
    endfor
    noa exe l:find." wincmd w"
  endif

  if l:edit
    exe l:edit." wincmd w"
  else
    abo split
    wincmd p
    exe "resize ".min([s:FL.height, winheight(0)])
    wincmd p
  endif

  let l:name = bufname(l:file.name)
  if !empty(l:name) && l:name ==# bufname()
    exe "normal! ".l:file.row.'G'
  else
    exe "edit +".l:file.row.' '.l:file.name
  endif
  exe "normal! ".l:file.col.'|'
  let s:FL.edit = s:FL.select

  call s:SetHiFind(1, 0)
endfunction

function s:FindNextPrevious(op, num)
  if !s:FindOpen() | return | endif
  let l:offset = ((a:op == '+') ? 1 : -1) * (a:num ? a:num : (v:count ? v:count : 1))
  let l:line = (!s:FL.edit && l:offset) ? 1 : max([1, s:FL.select + l:offset])
  exe "normal! ".l:line.'G'
  call s:FindEdit('=')
endfunction

function s:FindOlderNewer(op, n)
  if exists('s:Find.job')
    echo ' searching in progress...' | return
  endif
  let l:logs = len(s:FL.logs) - empty(s:FL.log.list)
  if !l:logs | echo ' no list' | return | endif

  let l:offset = ((a:op == '+') ? 1 : -1) * (a:n ? a:n : (v:count ? v:count : 1))
  let l:index = min([max([0, s:FL.index + l:offset]), l:logs-1])
  echo '  List  '.(l:index + 1).' / '.l:logs

  let l:win = winnr()
  call s:FindOpen()
  if s:FL.index != l:index
    let s:FL.index = l:index
    let l:log = s:FL.logs[l:index]
    let s:Find.hi = l:log.hi
    let s:Find.hi_tag += 1
    call s:FindSet(l:log.list, '=', l:log.status)
    call s:FindSelect(1)
    call s:SetHiFindWin(1, s:FL.buf)
  endif
  exe l:win." wincmd w"
endfunction

function s:FindCloseWin()
  if !s:FL.buf | return | endif
  let l:win = bufwinnr(s:FL.buf)
  if l:win != -1
    exe l:win." wincmd q"
  endif
endfunction

function s:FindClear()
  if !empty(s:Find.hi)
    call s:SetHiFindWin(0, 0)
    let s:Find.hi = ''
  endif
endfunction

function s:BufEnter()
  if !exists("w:HiMode") || !w:HiMode['>'] | return | endif
  call s:GetKeywords()
  call s:LinkCursorEvent('')
endfunction

function s:BufLeave()
  if !exists("w:HiMode") | return | endif
  call s:EraseHiWord()
endfunction

function s:BufHidden()
  if expand('<afile>') ==# s:FL.name
    call s:SetHiFindWin(0, 0)
  endif
endfunction

function s:WinEnter()
  if !exists("w:HiMode") | return | endif
  call s:LinkCursorEvent('')
endfunction

function s:WinLeave()
  if !exists("w:HiMode") | return | endif
  call s:UnlinkCursorEvent(0)
endfunction

function s:BufWinEnter()
  if bufname() ==# s:FL.name && !empty(s:Find.hi)
    call s:SetHiFindWin(1, s:FL.buf)
  endif
endfunction

function s:ColorSchemePre()
  let s:Current = []
  for l:k in ['HiOneTime', 'HiFollow']
    let l:v = s:GetColor(l:k)
    if !empty(l:v)
      call add(s:Current, [l:k, l:v])
    endif
  endfor
  for l:i in range(1, s:SchemeRange)
    let l:k = s:Color.l:i
    let l:v = s:GetColor(l:k)
    if !empty(l:v)
      call add(s:Current, [l:k, l:v])
    endif
  endfor
endfunction

function s:ColorScheme()
  if !exists("s:Current")
    return
  endif
  for l:c in s:Current
    exe 'hi' l:c[0].' '.l:c[1]
  endfor
  unlet s:Current
endfunction

function highlighter#Status()
  return getbufvar(s:FL.buf, 'Status')
endfunction

function highlighter#Airline(...)
  if winnr() == bufwinnr(s:FL.buf)
    let w:airline_section_a = ' Find '
    let w:airline_section_b = ''
    let w:airline_section_c = '%{highlighter#Status()}'
  endif
endfunction

function highlighter#Command(cmd, ...)
  if !exists("s:Colors")
    if !s:Load() | return | endif
  endif
  let l:arg = split(a:cmd)
  let l:cmd = get(l:arg, 0, '')
  let l:num = a:0 ? a:1 : 0
  let s:Search = 0

  if     l:cmd ==# ''         | echo ' Highlighter version '.s:Version
  elseif l:cmd ==# '+'        | call s:SetHighlight('+', 'n', l:num)
  elseif l:cmd ==# '-'        | call s:SetHighlight('-', 'n', l:num)
  elseif l:cmd ==# '+x'       | call s:SetHighlight('+', 'x', l:num)
  elseif l:cmd ==# '-x'       | call s:SetHighlight('-', 'x', l:num)
  elseif l:cmd ==# '>>'       | call s:SetMode('>', '')
  elseif l:cmd ==# 'default'  | call s:SetColors(1)
  elseif l:cmd ==# '/'        | call s:Find('n')
  elseif l:cmd ==# '/x'       | call s:Find('x')
  elseif l:cmd ==# '/next'    | call s:FindNextPrevious('+', l:num)
  elseif l:cmd ==# '/previous'| call s:FindNextPrevious('-', l:num)
  elseif l:cmd ==# '/older'   | call s:FindOlderNewer('-', l:num)
  elseif l:cmd ==# '/newer'   | call s:FindOlderNewer('+', l:num)
  elseif l:cmd ==# '/open'    | call s:FindOpen()
  elseif l:cmd ==# '/close'   | call s:FindCloseWin()
  elseif l:cmd ==# 'clear'    | call s:SetHighlight('--', 'n', 0) | call s:SetMode('-', '') | call s:FindClear()
  else
    echo ' Hi: no matching commands: '.l:cmd
  endif
  return s:Search
endfunction

let &cpo = s:cpo_save
unlet s:cpo_save
