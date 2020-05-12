# OneDrive

## 使い方

はじめに、Live SDKアプリケーションを作成します。

https://apps.dev.microsoft.com/#/appList/create/sapi にアクセスして適当な名前の `Live SDKアプリケーション` のアプリを作成します。

プラットフォームの追加から `ネイティブ アプリケーション` を追加します。
![image](https://user-images.githubusercontent.com/5038337/80963489-fe64d800-8e49-11ea-9d88-7e96e7892e94.png)

ここで得られる、 `クライアント ID` と、 `アプリケーションシークレット` を _.envファイル_ に記載します。

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

Dockerコンテナが起動したら、OneDriveの認証トークンを初期化します。

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

うまく動作すれば、OneDriveに読み取った結果のファイルがアップロードされているはずです！

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

[README.md](README.md)