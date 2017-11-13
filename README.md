# mncpllist

全国の市区町村の一覧（指定都市は区のみ）のリストを作成します。

## 必要なもの

Perl 5

## ファイルのダウンロード

### 都道府県コード及び市区町村コード

http://www.soumu.go.jp/denshijiti/code.html
(「都道府県コード及び市区町村コード」Excelファイル)

タブ区切りテキストファイルに変換します
* ./in/source-ctv.txt (1番目のシート)
* ./in/source-w.txt (2番目のシート)

### 郵便番号データベース

http://www.post.japanpost.jp/zipcode/download.html
(読み仮名データの促音・拗音を小書きで表記するもの)

./in/KEN_ALL.CSV

## スクリプトの実行

```csh
./bin/mkmncpllist.perl > out/hankaku.txt
./bin/mkmncpllist.perl -Z > out/zenkaku.txt
```

## 出力

タブ区切りです。各行は次のようになっています。

```
市区町村コード、（空白）、市郡等名、区町等名、（空白）、市郡等カナ、区町等カナ
```

## 出典

* 総務省「都道府県コード及び市区町村コード」(http://www.soumu.go.jp/denshijiti/code.html)
* 日本郵便株式会社「郵便番号データベース」(http://www.post.japanpost.jp/zipcode/download.html)
