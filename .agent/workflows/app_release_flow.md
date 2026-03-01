---
description: アプリ開発における修正からリリース用AAB作成、GitHubアップロードまでの一連のワークフロー
---

# アプリ開発・リリース基本フロー

アプリの修正や機能追加を行った際は、以下の手順を確実に行います。

## 1. プログラム全体の最終チェック
- `flutter analyze` を実行し、エラーや警告がゼロであることを確認します。
- 不要なデバッグプリント（`print`）や、非推奨のコード（例: `withOpacity`）を修正し、コードの品質を担保します。

## 2. GitHubへのアップロード
- プログラムに問題がないことを確認したら、変更内容をコミットしてGitHub（origin main）へプッシュします。
- これにより、最新の安全なコードがリポジトリに保存されます。

## 3. バージョンコードのアップデート
- Google Play Console へのアップロードには、既存のバージョンよりも高い「バージョンコード」が必要です。
- `pubspec.yaml` の `version` 行（例: `1.2.0+6` の `+` 以降の数字）をインクリメントします。
- バージョンコードに競合（既に使用されている等）がある場合は、さらに大きな数字に設定します。

## 4. AABファイルのビルド
- `flutter clean` を実行して古いビルドファイルを削除します。
- `flutter build appbundle --release` を実行し、リリース用のAABファイル（`app-release.aab`）を作成します。

## 5. ファイル保存場所の展開
- ビルド完了後、以下のディレクトリをエクスプローラーで表示し、ユーザーが即座にアップロードできるようにします。
- パス: `build\app\outputs\bundle\release\`

// turbo
3. npx -y explorer.exe /select,"C:\Users\user\.gemini\antigravity\scratch\fridge_keeper\build\app\outputs\bundle\release\app-release.aab"
