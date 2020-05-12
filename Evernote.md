# Evernote

## 使い方

はじめに、APIキーを取得します。

https://dev.evernote.com/ の `"GET AN API KEY"` ボタンを押してEvernote APIキーをリクエストします。

フォームに記入して`"Request Key"` ボタンを押すと Developer Email 宛に `APIキー` と `APIシークレット` が発行されます。
![image](https://user-images.githubusercontent.com/5038337/81729667-4ed1da80-94c7-11ea-8391-73852529b70d.png)

ここで発行される `APIキー` と `APIシークレット` を _.envファイル_ に記載します。

```
EVERNOTE_API_CLIENT_ID=(EvernoteのAPIキー)
EVERNOTE_API_CLIENT_SECRET=(EvernoteのAPIシークレット)
```

続いて、アプリのDockerコンテナを起動します。

```
$ git clone https://github.com/yasu-hide/brscan-skey-docker.git
$ cd brscan-skey-docker
$ docker-compose up -d
    Creating brscanskey_brscan-skey_1 ...
    Creating brscanskey_brscan-skey_1 ... done
```

Dockerコンテナが起動したら、Evernoteのアクセストークンを初期化します。

```
$ docker exec -it brscanskey_brscan-skey_1 /app/up2ever --init
```

入力を促されたら、手元のブラウザで記載のURLにアクセスします。

空白またはlocalhostに接続できないページが表示されたら、URLすべてを入力欄に記載してEnterします。

```
Redirected URL?

```

アクセストークンが正しく取得できているか確認してもよいでしょう。

```
$ cat evernote.access_token
  (取得したアクセストークンの文字列が表示される)
```

動作確認に、スキャナの「スキャン」ボタンを押して読み取りをしてみてください。

うまく動作すれば、Evernoteに読み取った結果のファイルがアップロードされているはずです！

----

## 設定 (.envファイル)

### EVERNOTE_API_CLIENT_ID

EvernoteのAPIキーを記載します。

変更例:
```
EVERNOTE_API_CLIENT_ID=appname
```

必須の設定です。

### EVERNOTE_API_CLIENT_SECRET
EvernoteのAPIシークレットを記載します。

変更例:
```
ONEDRIVE_API_CLIENT_SECRET=vquDZST82663$@wkjdMXY_^
```

必須の設定です。

----

[README.md](README.md)