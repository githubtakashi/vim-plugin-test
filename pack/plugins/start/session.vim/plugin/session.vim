" すでにスクリプトをロードした場合は終了
if exists('g:loaded_session')
	finish
endif
let g:loaded_session = 1

" commandはExコマンドを定義
" 次の定義では:SessionListコマンドでcall session#sessions()が実行されるようになる
command! SessionList call session#sessions()

" -nargsでコマンドが受け取れる引数の数を設定できる
" デフォルトは引数を受け取らないので1個の引数を受け取れるようにする
" <q-args>は引数を意味する
command! -nargs=1 SessionCreate call session#create_session(<q-args>)

