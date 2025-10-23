# kyosan-eats-demo

このリポジトリは、バックエンド (FastAPI) とフロントエンド (React/Vite 想定) を組み合わせた開発用のサンプルプロジェクトです。

## 概要

- バックエンド: Python (FastAPI)
- フロントエンド: React + Vite
- コンテナ管理: Docker / Docker Compose

## 主な構成

- `Dockerfile.backend` - バックエンド用 Dockerfile
- `Dockerfile.react` - フロントエンド用 Dockerfile (存在する場合)
- `compose.yml` - Docker Compose 設定（サービス: backend, frontend）
- `backend/` または `app/` - バックエンドのソース
- `frontend/` または `src/` - フロントエンドのソース
- `.env` - 環境変数（Supabase 等の秘密情報はここに置く）

## セットアップ

以下はローカル開発向けの手順です。macOS (zsh) を想定しています。

### 共通準備

1. Docker と Docker Compose をインストールしてください。
2. リポジトリをチェックアウトし、プロジェクトルートへ移動:

```bash
git clone ~
```
```bash
cd kyosan-eats-demo
```


### バックエンド（開発）

#### 目的
FastAPI サービスが正しく起動するか、エンドポイント（/docs 等）にアクセスできるか、Supabase 連携が動くかを確認します。

#### 1) 環境変数の準備
`.env.example` がある場合はコピーして必要な値（SUPABASE_URL, SUPABASE_ANON_KEY など）をセットしてください:
#### .env をエディタで編集してください
```bash
cp .env.example .env
```

#### 2) ローカルで素の Python 実行環境で動作確認（任意）
ローカル仮想環境でまず動くかを確認すると原因切り分けが楽です。

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
# FastAPI を直接起動して動作確認
uvicorn app:app --reload --host 0.0.0.0 --port 8000
# ブラウザで http://localhost:8000/docs を確認
```

成功基準:
- ブラウザで `/docs` が開く
- 基本的な GET/POST エンドポイントに 200 応答が返る

#### 3) Docker での確認（推奨）
コンテナ上で動くことを確認します。プロジェクトルートで実行:

#### イメージをビルドして backend を起動
```bash
docker compose up --build -d backend
```
#### ログを追う
```
docker compose logs -f backend
```
#### コンテナに入る（必要なら）
```
docker compose exec backend bash
```

コンテナ起動後の確認:
- ブラウザで `http://localhost:8000` を開く
- ブラウザで `http://localhost:8000/docs` を開く
- `docker compose ps` で `backend` が `Up` になっている

#### 4) Supabase 連携の簡易テスト
`.env` に SUPABASE の URL/キーを入れている前提で、簡単な接続テストを実行できます。

コンテナ内で（またはローカル venv 内で）:

```bash
python -c "from supabase import create_client; import os; c=create_client(os.environ['SUPABASE_URL'], os.environ['SUPABASE_ANON_KEY']); print('ok' if c else 'ng')"
```

より確実には、付属のスクリプト（例: `supabase_test.py`）があれば実行してください:

```bash
docker compose exec backend python supabase_test.py
```
#### 5) `backend.py` の動作確認（Docker コンテナ内）
   コンテナ環境で確認する場合の手順です。コンテナに入ってから `requirements.txt` をインストール済みであることを確認し、`backend.py` を実行します。
   #### backend.pyを実行
   ```bash
   docker compose exec backend　python backend.py
   ```

#### 6) トラブルシュート用コマンド

```bash
# ポート使用状況の確認（macOS）
lsof -nP -iTCP:8000 -sTCP:LISTEN

# コンテナログの確認
docker compose logs -f backend

# ビルドし直し
docker compose up --build -d backend
```

## 注意事項
外部ライブラリを使用する場合は、必ず `requirements.txt` にライブラリ名とバージョンを明記してください。
仮想環境で実行した際に「ModuleNotFoundError: No module named '...'」や "~ not found" のようなエラーが発生することがあります。エラーが出た場合は、該当するライブラリとバージョンを `requirements.txt` に追記してからDockerを再起動してください。



### フロントエンド（開発）

概要: Docker 上で動作する React（Vite）開発環境を想定しています。ソースはホスト側で編集し、コンテナ内で依存解決・実行します。ホットリロード（HMR）対応。既定のアクセス先は `http://localhost:5173` です。

#### 1) app ディレクトリの用意
既存の React/Vite アプリがない場合は Vite のテンプレートで作成します（TypeScript 推奨）:

#### プロジェクトのルートで実行
```bash
npm create vite@latest frontend -- --template react
```

すでに別の React プロジェクトがある場合は、その中身を `./frontend` に配置してください。


#### 2) 起動・動作確認
イメージ作成、コンテナを起動します（初回は依存が自動インストールされる仕組みがあればそれを利用）:

```bash
docker compose build frontend
```
```
docker compose up -d frontend
```
### ログを追う
```
docker compose logs -f frontend
```

### コンテナ内でコマンド実行（依存追加やビルド）
```
docker compose exec frontend bash
```
```
npm install <package>
```

ブラウザで `http://localhost:5173` を開いて画面が表示され、ソース編集が即時反映されればセットアップ完了です。

#### 4) よくある操作例

```bash
# パッケージ追加
docker compose exec frontend npm i <package>

# 本番ビルド（コンテナ内で実行）
docker compose exec frontend npm run build
```

#### 5) 注意事項
- `node_modules` は named volume に保持し、ホストに展開しないことを推奨します（Apple Silicon など環境差異を回避）。
- HMR が反映されない場合は `CHOKIDAR_USEPOLLING=true` の有無を確認してください。
- ポート `5173` が使用中だと起動に失敗します。必要に応じて `compose.yml` のポート設定を変更してください。


## 注意事項

- ホスト側でポートが既に使われていると Compose の起動が失敗します。ポート競合は `lsof -nP -iTCP:<port> -sTCP:LISTEN` で確認できます。
- 開発時はバインドマウント（`volumes:` で `./backend:/app` 等）を使うため、ホストの変更が即コンテナに反映されます。一方、本番環境ではマウントせずにイメージだけで動かすことを推奨します。
- `node_modules` のような生成物はボリュームで分離するか `.dockerignore` で除外してください。
- `.env` に秘密情報（API キー等）を置くときは取り扱いに注意し、リポジトリにコミットしないでください。

## ライセンス

このプロジェクトは MIT ライセンスの下で公開します。

---
