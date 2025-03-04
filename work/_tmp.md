#### **`WITH`句: `sales_data` CTE (共通テーブル式)**

```sql
WITH sales_data AS (
  SELECT 
    sales_ymd, 
    SUM(amount) AS amount,
    LAG(sales_ymd, 3, -1) OVER (ORDER BY sales_ymd) AS lag_ymd
  FROM 
    receipt
  GROUP BY 
    sales_ymd
  HAVING 
    SUM(amount) IS NOT NULL
)
```

1. **`sales_ymd` (売上日)ごとの集計**  
   `SUM(amount)` により、各売上日 (`sales_ymd`) ごとに売上金額 (`amount`) の合計を計算します。

2. **`LAG(sales_ymd, 3, -1) OVER (ORDER BY sales_ymd)`**  
   `LAG()` 関数はウィンドウ関数で、現在の行の値から `n` 行前の値を取得します。ここでは、3回前の `sales_ymd` を `lag_ymd` として取得しています。もし3回前の売上日が存在しない場合、デフォルト値 `-1` を格納します。  
   - **`OVER (ORDER BY sales_ymd)`** は、`sales_ymd` の昇順に並べてウィンドウ関数を適用することを意味します。

3. **`GROUP BY sales_ymd`**  
   `sales_ymd` ごとにデータをグループ化し、そのグループ内で `SUM(amount)` を計算します。

4. **`HAVING SUM(amount) IS NOT NULL`**  
   `HAVING`句により、売上金額の合計が `NULL` ではないデータのみを対象にしています。`NULL` の場合は売上がなかったため、対象外となります。

#### **メインのSELECT文**

```sql
SELECT 
  L.sales_ymd,
  L.amount,
  R.sales_ymd AS lag_sales_ymd,
  R.amount AS lag_amount
FROM 
  sales_data L
INNER JOIN 
  sales_data R
ON (
  L.lag_ymd <= R.sales_ymd 
  AND L.sales_ymd > R.sales_ymd
)
ORDER BY 
  L.sales_ymd, R.sales_ymd
```

1. **`INNER JOIN`による自己結合**  
   `sales_data` CTEを `L` と `R` という2つのエイリアスを使って結合しています。これは自己結合 (self join) です。  
   - `L` は現在の売上データを表し、`R` は3回前の売上データを表します。

2. **結合条件**  
   - `L.lag_ymd <= R.sales_ymd` は、`L` の3回前の売上日 (`lag_ymd`) が `R` の売上日 (`sales_ymd`) 以下であることを確認します。
   - `L.sales_ymd > R.sales_ymd` は、`L` の売上日 (`sales_ymd`) が `R` の売上日 (`sales_ymd`) よりも後であることを確認します。

   これにより、`L` の売上日の前に `R` の売上日が存在し、かつ `L` の売上日が `R` の売上日よりも後である場合に、両者のデータが結合されます。要するに、`L` と `R` の売上日が3日以内の範囲で一致する場合のみ結合されます。

3. **選択するカラム**  
   - `L.sales_ymd`: 現在の売上日
   - `L.amount`: 現在の売上金額
   - `R.sales_ymd AS lag_sales_ymd`: 3回前の売上日
   - `R.amount AS lag_amount`: 3回前の売上金額

4. **`ORDER BY L.sales_ymd, R.sales_ymd`**  
   結果は `L.sales_ymd` と `R.sales_ymd` の昇順で並べ替えられます。これにより、現在の売上日と3回前の売上日が順番に整理されます。
