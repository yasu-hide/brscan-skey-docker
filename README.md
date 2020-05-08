# brscan-skey-docker

スキャンした画像をクラウドにアップロードしたい要件でFAX機能が無いレーザー複合機を買ったら、クラウドアップロード機能はFAX付き機種しか対応していなくて詰みました。

仕方なしに作った、ラズパイ(もどき)で動くbrother4 (ブラザー複合機)向けのonedriveうｐろだです。

Docker(docker-compose)で動きます。

- スキャナの制御に、sane-utils と [brscan4ドライバ](https://support.brother.co.jp/j/b/downloadhowto.aspx?c=jp&lang=ja&prod=dcpl2550dw&os=128&dlid=dlf103892_000&flang=1001&type3=565) を利用しています。
- スキャナボタン操作に、[brscan-skey](https://support.brother.co.jp/j/b/downloadhowto.aspx?c=jp&lang=ja&prod=dcpl2550dw&os=128&dlid=dlf103879_000&flang=1001&type3=569) を利用しています。
- スキャナの検出に、[avahi](http://avahi.org/) を利用しています。
- 文字の認識に、[tesseract](https://github.com/tesseract-ocr/) を利用しています。
- onedriveのアップロードに、[bash-onedrive-upload](https://github.com/fkalis/bash-onedrive-upload) を利用しています。

----

## 使い方

まずはじめに、Live SDKアプリケーションを作成します。

https://apps.dev.microsoft.com/#/appList/create/sapi にアクセスして適当な名前の `Live SDKアプリケーション` のアプリを作成します。

プラットフォームの追加から `ネイティブ アプリケーション` を追加します。
![image](https://user-images.githubusercontent.com/5038337/80963489-fe64d800-8e49-11ea-9d88-7e96e7892e94.png)

ここで得られる、 `クライアント ID` と、 `アプリケーションシークレット` を設定ファイルに記載します。

_.envファイル_ にonedrive関連の設定をします。

設定項目は後述します。

```
ENABLE_OCR=(無効は0、有効は1)
ONEDRIVE_API_CLIENT_ID=(Live SDKアプリケーションのクライアントID)
ONEDRIVE_API_CLIENT_SECRET=(Live SDKアプリケーションのアプリケーションシークレット)
ONEDRIVE_DRIVE_RESOURCE=root
ONEDRIVE_ROOT_FOLDER=/
```

続いて、アプリのDockerコンテナを起動します。

```
$ git clone https://github.com/yasu-hide/brscan-skey-docker.git
$ cd brscan-skey-docker
$ docker-compose up -d
    Creating brscanskey_brscan-skey_1 ...
    Creating brscanskey_brscan-skey_1 ... done
```

Dockerコンテナが起動したら、onedriveの認証トークンを初期化します。

```
$ docker exec -it brscanskey_brscan-skey_1 /app/bash-onedrive-upload/onedrive-authorize
```

認可コードの入力を促されたら、手元のブラウザで記載のURLにアクセスします。

空白のページが表示されたら、URLの `code=` から `&` までの文字列(赤線部分)を認可コードの入力欄に記載してEnterします。

```
Please open the following URL in your browser and follow the steps until you see a blank page:
https://login.live.com/oauth20_authorize.srf?client_id=(CLIENT_ID)&scope=wl.offline_access%20onedrive.readwrite&response_type=code&redirect_uri=https://login.live.com/oauth20_desktop.srf

When ready, please enter the value of the code parameter (from the URL of the blank page) and press return
```

![image](https://user-images.githubusercontent.com/5038337/80965326-4a654c00-8e4d-11ea-853e-dc9b94b9910e.png)

次のメッセージが表示されたら、認証トークンの取得が完了しています。
```
It seems like we have a refresh token, so we are ready to go
```

認証トークンが正しく取得できているか確認してもよいでしょう。

```
$ cat onedrive.refresh_token
  (取得した認証トークンの文字列が表示される)
```

動作確認に、スキャナの「スキャン」ボタンを押して読み取りをしてみてください。

うまく動作すれば、onedriveに読み取った結果のファイルがアップロードされているはずです！

----

## 設定 (.envファイル)

### ENABLE_OCR

tesseract-ocrによる文字起こしを設定します。

無効は0、有効は1です。

変更例:
```
ENABLE_OCR=1
```

初期値は __0__ です。

### ONEDRIVE_API_CLIENT_ID

Live SDKアプリケーションのクライアントIDを記載します。

変更例:
```
ONEDRIVE_API_CLIENT_ID=00000000443C5ED1
```

必須の設定です。

### ONEDRIVE_API_CLIENT_SECRET
Live SDKアプリケーションのアプリケーションシークレットを記載します。

変更例:
```
ONEDRIVE_API_CLIENT_SECRET=vquDZST82663$@wkjdMXY_^
```

必須の設定です。

### ONEDRIVE_DRIVE_RESOURCE
[特殊なフォルダ](https://docs.microsoft.com/ja-jp/onedrive/developer/rest-api/api/drive_get_specialfolder) を使用する場合に変更します。

設定できる値はOneDrive Developerのドキュメントを参照してください。

変更例:
```
ONEDRIVE_DRIVE_RESOURCE=special/documents
```

初期値は、 __root__ です。

### ONEDRIVE_ROOT_FOLDER
ファイルの設置場所を指定する場合に変更します。

変更例:
```
ONEDRIVE_ROOT_FOLDER=スキャン画像
```

初期値は、 __/__ です。

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
* Eメール (brscan-skey添付のメール送信スクリプト)
* ファイル (`scantofile.sh`)
    * 解像度を __100__ 、フォーマットを __pnm__ に設定する
    * `scanimage` コマンドを識別されたスキャナデバイス名や上記設定値で起動して画像を取り込み、PNMファイルに出力する
    * `onedrive-upload` コマンドでonedriveにアップロードする
* イメージ (`scantoimage.sh`)
    * 解像度を __600__ 、フォーマットを __jpeg__ に設定する
    * `scanimage` コマンドを識別されたスキャナデバイス名や上記設定値で起動して画像を取り込み、JPEGファイルに出力する
    * `onedrive-upload` コマンドでonedriveにアップロードする
* OCR (`scantoocr.sh`)
    * 解像度を __300__ 、フォーマットを __pnm__ に設定する
    * `scanimage` コマンドを識別されたスキャナデバイス名や上記設定値で起動してバッチモードで画像を取り込む
    * `tesseract-ocr` コマンドで文字認識して、または`convert` コマンドで取り込んだ複数の画像を結合して、PDFファイルに出力する
    * `onedrive-upload` コマンドでonedriveにアップロードする
