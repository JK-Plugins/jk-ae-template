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



## このテンプレート自体を変更する際の注意点

### 1. エスケープ


Justfileではcargo-generateと同じ{{}}がプレースホルダーの役割を担っているため、generateコマンドを打った際にバグが起きてしまいます。
{ %raw% }{{ Justfile内の変数名 }}{ %endraw% }のように、エスケープしてください。

