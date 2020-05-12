# brscan-skey-docker

スキャンした画像をクラウドにアップロードしたい要件でFAX機能が無いレーザー複合機を買ったら、クラウドアップロード機能はFAX付き機種しか対応していなくて詰みました。

仕方なしに作った、ラズパイ(もどき)で動くbrother4 (ブラザー複合機)向けのうｐろだです。

Docker(docker-compose)で動きます。

- スキャナの制御に、sane-utils と [brscan4ドライバ](https://support.brother.co.jp/j/b/downloadhowto.aspx?c=jp&lang=ja&prod=dcpl2550dw&os=128&dlid=dlf103892_000&flang=1001&type3=565) を利用しています。
- スキャナボタン操作に、[brscan-skey](https://support.brother.co.jp/j/b/downloadhowto.aspx?c=jp&lang=ja&prod=dcpl2550dw&os=128&dlid=dlf103879_000&flang=1001&type3=569) を利用しています。
- スキャナの検出に、[avahi](http://avahi.org/) を利用しています。
- 文字の認識に、[tesseract](https://github.com/tesseract-ocr/) を利用しています。
- OneDriveのアップロードに、[bash-onedrive-upload](https://github.com/fkalis/bash-onedrive-upload) を利用しています。

----
## アップロード先ごとのドキュメント
* [OneDrive.md](OneDrive.md)
* [Evernote.md](Evernote.md)
----
## 動作について

`brscan-skey` の動作概要です。

### コンテナ起動時の動作 (entrypoint.sh)
* `dbus` デーモンと`avahi` デーモンを起動する
* Zeroconfネットワークで **_uscans._tcp** (ネットワークスキャナ)を探索する
* `brsaneconfig4` でスキャナの名前やIPv4アドレスを登録する
* `brscan-skey` デーモンを起動する
    * SNMP Set-Requestでスキャナにコンピュータを登録する
    * _udp/54925_ でListenし、スキャナからデータ取り込み指令を待つ

### スキャンボタンが押された時の動作 (brscan-skey_scripts/)
* `brscan-skey` デーモンが _udp/54925_ で受信したパケットを識別する
    * _Eメール, イメージ, OCR, ファイル_ を識別して、`brscan-skey.cfg` に記載されたプログラムを起動する
* Eメール (`scantoemail.sh`)
    * 解像度を __300__ 、フォーマットを __jpeg__ に設定する
    * `scanimage` コマンドを識別されたスキャナデバイス名や上記設定値で起動して画像を取り込み、JPEGファイルに出力する
    * `up2ever` コマンドでEvernoteにアップロードする
* ファイル (`scantofile.sh`)
    * 解像度を __100__ 、フォーマットを __pnm__ に設定する
    * `scanimage` コマンドを識別されたスキャナデバイス名や上記設定値で起動して画像を取り込み、PNMファイルに出力する
    * `onedrive-upload` コマンドでOneDriveにアップロードする
* イメージ (`scantoimage.sh`)
    * 解像度を __600__ 、フォーマットを __jpeg__ に設定する
    * `scanimage` コマンドを識別されたスキャナデバイス名や上記設定値で起動して画像を取り込み、JPEGファイルに出力する
    * `onedrive-upload` コマンドでOneDriveにアップロードする
* OCR (`scantoocr.sh`)
    * 解像度を __300__ 、フォーマットを __pnm__ に設定する
    * `scanimage` コマンドを識別されたスキャナデバイス名や上記設定値で起動してバッチモードで画像を取り込む
    * `tesseract` コマンドで文字認識して、または`convert` コマンドで取り込んだ複数の画像を結合して、PDFファイルに出力する
    * `onedrive-upload` コマンドでOneDriveにアップロードする
