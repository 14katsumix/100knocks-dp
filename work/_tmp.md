このSQLクエリは、`customer` テーブルと `receipt` テーブルを結合し、年齢を10歳単位でグループ化し、性別ごとの売上金額を集計するものです。

```sql
SELECT
  CAST(FLOOR(c.age / 10.0) * 10 AS INTEGER) AS age_range,
  SUM(CASE WHEN c.gender_cd = '0' THEN r.amount ELSE 0 END) AS male,
  SUM(CASE WHEN c.gender_cd = '1' THEN r.amount ELSE 0 END) AS female,
  SUM(CASE WHEN c.gender_cd = '9' THEN r.amount ELSE 0 END) AS unknown
FROM 
  customer c
INNER JOIN 
  receipt r 
USING (customer_id)
GROUP BY 
  age_range
ORDER BY 
  age_range;
```

### 解説

1. **年齢範囲 (`age_range`) の計算**:
   - `CAST(FLOOR(c.age / 10.0) * 10 AS INTEGER)` で、`age` を10で割り、小数部分を切り捨て、10倍して年齢範囲を作成します。
   - 例えば、`age` が `23` の場合、`FLOOR(23 / 10.0) * 10` は `20` となります。

2. **性別ごとの売上金額の集計**:
   - `SUM(CASE WHEN c.gender_cd = '0' THEN r.amount ELSE 0 END)` で、性別コードが `0`（男性）の場合に売上金額 `amount` を集計します。同様に、性別コードが `1`（女性）および `9`（不明）の場合も処理します。

3. **`INNER JOIN` と `USING`**:
   - `customer` テーブルと `receipt` テーブルを `customer_id` で結合しています。`USING (customer_id)` は、`customer_id` が両方のテーブルに存在する場合に使用します。

4. **`GROUP BY`**:
   - `age_range` でグループ化し、各年齢範囲ごとの売上金額を集計します。

5. **`ORDER BY`**:
   - 結果を `age_range` の昇順で並べ替えます。
