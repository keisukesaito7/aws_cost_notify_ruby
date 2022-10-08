## 環境構築

```
$ bundle config set --local path vendor/bundle
$ bundle install
```

## デプロイ

- Lambda: costNotifyRuby
- lambda_function.rb と vendor ディレクトリを圧縮 → .zip ファイルをアップロード

link: https://docs.aws.amazon.com/ja_jp/lambda/latest/dg/ruby-package.html#ruby-package-dependencies
