import os
import time

import psycopg2
from flask import Flask, jsonify

app = Flask(__name__)


def get_conn():
    return psycopg2.connect(
        host=os.environ["DB_HOST"],
        port=os.environ.get("DB_PORT", "5432"),
        dbname=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        connect_timeout=5,
        sslmode="require",
    )


def init_db():
    for _ in range(10):
        try:
            with get_conn() as conn, conn.cursor() as cur:
                cur.execute(
                    "CREATE TABLE IF NOT EXISTS visits ("
                    "id SERIAL PRIMARY KEY, ts TIMESTAMPTZ DEFAULT now())"
                )
            return
        except Exception as exc:  # DB may still be starting
            print(f"DB init retry: {exc}", flush=True)
            time.sleep(3)


@app.route("/")
def index():
    with get_conn() as conn, conn.cursor() as cur:
        cur.execute("INSERT INTO visits DEFAULT VALUES")
        cur.execute("SELECT count(*) FROM visits")
        count = cur.fetchone()[0]
    return jsonify(message="Hello from ECS Fargate", visits=count,
                   host=os.uname().nodename)


@app.route("/health")
def health():
    # Liveness only: does not touch the DB so a DB blip doesn't kill tasks.
    return jsonify(status="ok")


@app.route("/load")
def load():
    # CPU-bound endpoint used for load testing / triggering auto scaling.
    total = 0
    for i in range(2_000_000):
        total += i * i
    return jsonify(result=total)


init_db()
