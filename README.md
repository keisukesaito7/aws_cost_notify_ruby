## 環境構築

```
$ bundle init
$ bundle config set --local path vendor/bundle
$ bundle install
```

## デプロイ

- Lambda: costNotifyRuby
- lambda_function.rb と vendor ディレクトリを圧縮 → .zip ファイルをアップロード

