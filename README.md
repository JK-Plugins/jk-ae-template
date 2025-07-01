# `JK-AE-Template` のインストールと使い方

## 使い方


まず、cargo-generateをインストールしてください。

```sh
cargo install cargo-generate
```

テンプレートから新しいプロジェクトを作成するには、以下のコマンドを実行します。

```sh
cargo generate --git https://github.com/cargo-generate/cargo-generate.git
```

コマンド実行時に聞かれるものについてです。

project-name : フォルダなどに使用される名前。

plugin_name : AE上で出る名前。

plugin_category : AE上で分別されるプラグインのカテゴリー。



## このテンプレート自体を変更する際の注意点

### 1. エスケープ


Justfileではcargo-generateと同じ{{}}がプレースホルダーの役割を担っているため、generateコマンドを打った際にバグが起きてしまいます。
{ %raw% }{{ Justfile内の変数名 }}{ %endraw% }のように、エスケープしてください。

