# LocalMinMax

## LocalMinMaxとは
チャートのローソク足から局所特徴と呼ばれる特徴点を検出し、特徴点の傾向からその後のチャートの抵抗帯を推測するためのAPI、または自動売買のためのEAを提供します。<br>
本機能を利用することにより独自にインジケータやEAを作成することも可能です。

## 環境構築
```
$ git clone <this repo>
$ cd LocalMinMax
$ git config diff.utf16.textconv 'iconv -f utf-16 -t utf-8'
```

## 機能について

LocalMinMaxは以下の機能で構成されています。
- 局所特徴を検出するAPI
- 局所特徴から過去の反発点を検出するAPI
- 過去の反発点から未来の抵抗帯を推測するAPI
