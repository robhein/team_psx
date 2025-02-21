/*
 * メモリカード対応コントローラAPI関数
 * メモリカードBIOS関数がタイムアウトすると後続するコントローラへのアクセスが
 * 失敗する。（カーネルのバグ）
 * これに対応するため、コントローラ受信バッファの内容を保存しておき、タイムアウ
 * ト発生時にこれを復元する。
 * 低レベルインタフェースであるlibapiのコントローラサービスにより、上記機能を
 * 備えたコントローラアクセス関数群を記述する。
*/

/* 受信バッファと保存バッファ *.
static unsigned char _c_buf[4][34];

/*
 * 初期化
*/
_init_pad()
{
	/* 受信バッファをカーネルに登録しドライバを初期化 */
	InitPAD(&_c_buf[0][0],34,&_c_buf[1][0],34);

	/* 保存バッファを「通信失敗」データで初期化 */
	_c_buf[2][0] = _c_buf[3][0] = 0xff;

	/* コントローラドライバを起動 */
	StartPAD();
}


/*
 * コントローラ状態読みだし
 * 引数chanはコントローラポートを示す。向かって左が0、右が1。
*/
_get_cont(chan)
long chan;
{
	unsigned long w;

	/* 通信失敗（「コントローラなし」のはず） */ならば0x8000ffffを返す */
	if(_c_buf[chan][0]==0xff)   return 0x8000ffff;

	/* 受信バッファ内容の保存 */
	memcpy(&_c_buf[chan+2], &_c_buf[chan], 34);

	/* 2バイトのボタン状態（リトルエンディアン）を1変数にパッキング */
	w = (unsigned long)_c_buf[chan][2];
	return (long)( (w<<8) | (unsigned long)_c_buf[chan][3] );
}


/*
 * 受信バッファを復元
*/
_copy_back()
{
	memcpy(&_c_buf[0], &_c_buf[2], 34);
	memcpy(&_c_buf[1], &_c_buf[3], 34);
}
