" 現在のパスからパスセパレータを取得
" 詳細は`:h fnamemodify()`を参照
let s:sep = fnamemodify('.', ':p')[-1:]

function! session#create_session(file) abort
	" SessionCreateの引数をfileで受け取れるようにする
	" join()でセッションファイル保存先へのフルパスを生成し、mksession!でセッションファイルを作成
	execute 'mksession!' join([g:session_path, a:file], s:sep)

	" redrawで画面を再描画してメッセージを出力する
	redraw
	echo 'session.vim: created'
endfunction

function! session#load_session(file) abort
	" `:source`で渡されるセッションファイルをロードする
	execute 'source' join([g:session_path, a:file], s:sep)
endfunction

" エラーメッセージ（赤）を出力する関数
" echohl でコマンドラインの文字列をハイライトできる。詳細は:h echohl参照
function! s:echo_err(msg) abort
	echohl ErrorMsg
	echomsg 'session.vim:' a:msg
	echohl None
endfunction

" セッションファイルを取得する関数
" 結果：['file1', 'file2', ...]
function! s:files() abort
	" g:session_path からセッションファイルの保存先を取得する
	" g: はグローバルな辞書変数なので get() を使用して指定したキーの値を取得できる
	let session_path = get(g:, 'session_path', '')
	
	" g:session_pathが設定されていない場合はエラーメッセージを出し空のリストを返す
	if session_path is# ''
		call s:echo_err('g:session_path is empty')
		return []
	endif
	
	" file という引数を受け取り、そのファイルがディレクトリでなければ1を返すLambda
	let Filter = { file -> !isdirectory(session_path . s:sep . file)}
	" readdir の第２引数に Filter を使用することでファイルだけが入ったリストが取得できる
	return readdir(session_path, Filter)
endfunction


" リストを表示できるバッファを作成(すでにあれば表示)
" s:files()で取得できたファイル一覧を一時バッファに書き出し、ユーザが選択できるようにする

" セッション一覧を表示するバッファ名
let s:session_list_buffer = 'SESSIONS'

function! session#sessions() abort
	let files = s:files()
	if empty(files)
		return
	endif

	" バッファが存在している場合
	if bufexitsts(s:session_list_buffer)
	  " バッファがウィンドウに表示されている場合は`win_gotoid`でウィンドウに移動する
	  let winid = bufwinid(s:session_list_buffer)
	  if winid isnot# -1
	    call win_gotoid(winid)

	  " バッファがウィンドウに表示されていない場合は`sbuffer`で新しいウィンドウを作成してバッファを開く 
	  else
	    execute 'sbuffer' s:session_list_buffer 
	  endif

	else
	  " バッファが存在していないときは、`new`で新しいバッファを作成する
 	  execute 'new' s:session_list_buffer
	  
	  " バッファの種類を指定する
	  " ユーザが書き込むことはないバッファなので`nofile`に設定する
	  " 詳細は`:h buftype`を参照
	  set buftype=nofile

	  " 1.セッション一覧のバッファで`q`を押下するとバッファを破棄

	  " 2.`Enter`でセッションをロード
	  " 上記1.2.のキーマッピングを定義する
	  " 
	  " <C-u>と<CR>はそれぞれコマンドラインでctrl-uとEnterを押下したときの動作。
	  " <buffer>は現在のバッファにのみキーマップを設定する。
	  " <silent>はキーマップで実行されるコマンドがコマンドラインに表示されないようにする。
	  " <Plug>という特殊な文字を使用するとキーを割り当てないマップを用意できる。
	  " ユーザはこのマップを使用して自分の好きなキーマップを設定できる。
	  "
	  " \ は改行する時に必要
	  nnoremap <silent> <buffer>
	  	\ <Plug>(session-close)
		\ :<C-u>bwipeout!<CR>

	  nnoremap <silent> <buffer>
		\ <Plug>(session-open)
		\ :<C-u>call session#load_session(trim(getline('.')))<CR>

	  " <Plug>マップをキーボードのキーにマッピングする
	  " `q` は最終的に :<C-u>bwipeout!<CR>
	  " `Enter` は最終的に :<C-u>call session#load_session()<CR>
	  " が実行される
	  nmap <buffer> q <Plug>(session-close)
	  nmap <buffer> <CR> <Plug>(session-open)
	endif
	
	" セッションファイルを表示する一時バッファのテキストをすべて削除して、取得したファイル一覧をバッファに挿入
	%delete _ 
	call setline(1, files)
endfunction 
