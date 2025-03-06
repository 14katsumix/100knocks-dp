#### 1. `joined_data` の作成

```sql
WITH joined_data AS (
  SELECT
    c.customer_id,
    CAST((FLOOR(age / 10.0) * 10.0) AS INTEGER) AS age_range,
    CASE c.gender_cd
      WHEN '0' THEN '00'
      WHEN '1' THEN '01'
      ELSE '99'
    END AS gender_cd,
    r.amount
  FROM
    customer c
  INNER JOIN
    receipt r
  USING(customer_id)
)
```

`customer` テーブルと `receipt` テーブルを結合し、`age` と `gender_cd` を変換します。

- **`INNER JOIN` による結合**  
  - `customer_id` をキーに `customer` テーブルと `receipt` テーブルを結合します。
  
- **年齢範囲 (`age_range`) の計算**  
  - `age` を 10 歳刻みの年齢範囲に変換します（例: `age` が 23 の場合、`age_range` は 20 ）。
  - `FLOOR(age / 10.0) * 10.0` により、年齢を 10 の倍数に切り下げます。

- **性別 (`gender_cd`) の変換**  
  - `gender_cd` の値を `'0'` → `'00'`、`'1'` → `'01'`、それ以外 → `'99'` に変換します。

#### 2. `all_combinations` の作成

```sql
all_combinations AS (
  SELECT
    jd.age_range, g.gender_cd
  FROM
    (SELECT DISTINCT age_range FROM joined_data) AS jd
  CROSS JOIN
    (VALUES ('00'), ('01'), ('99')) AS g(gender_cd)
)
```

- **`CROSS JOIN` による全組み合わせの作成**  
  - `age_range` の異なる値と `gender_cd` の3種類 (`'00'`, `'01'`, `'99'`) の全組み合わせを生成します。
  - `age_range` は `joined_data` から取得し、`gender_cd` は `VALUES` 句で指定しています。

#### 3. `sales_summary` の作成

```sql
sales_summary AS (
  SELECT
    gender_cd,
    age_range,
    SUM(amount) AS sum_amount
  FROM
    joined_data
  GROUP BY
    gender_cd, age_range
)
```

- **売上金額 (`sum_amount`) の集計**  
  - `SUM(amount)` により、(`gender_cd`, `age_range`) の各組み合わせごとの売上金額を集計します。
  - `GROUP BY` を使用して、`gender_cd` と `age_range` ごとに集計を行います。

#### 4. メインの `SELECT` 文と結合

```sql
SELECT
  ac.age_range,
  ac.gender_cd,
  COALESCE(ss.sum_amount, 0.0) AS sum_amount
FROM
  all_combinations ac
LEFT JOIN
  sales_summary ss
USING   
  (age_range, gender_cd)
ORDER BY
  ac.gender_cd, ac.age_range
```

- **`LEFT JOIN` によるデータの結合**  
  - `all_combinations` を基準に、`sales_summary` を (`age_range`, `gender_cd`) で `LEFT JOIN` します。
  - `sales_summary` に該当データがない場合は `NULL` になるため、それを `COALESCE()` で補完します。

- **`COALESCE()` による `NULL` 値の補完**  
  - `COALESCE(ss.sum_amount, 0.0)` により、売上金額が `NULL` の場合は `0.0` に置き換えます。
  
- **`ORDER BY` による並び替え**  
  - 結果を `gender_cd`、`age_range` の昇順にソートします。
