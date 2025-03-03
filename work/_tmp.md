
- **`sales_by_date` CTE で売上合計を計算**  
  - `sales_ymd` ごとに `amount` の合計を算出します。  
  - `HAVING SUM(amount) IS NOT NULL` により、売上データが存在しない日を除外します。  

- **`sales_by_date_with_lag` CTE で前日のデータを取得**  
  - `LAG(sales_ymd) OVER win` により、前日の `sales_ymd` を取得します。  
  - `LAG(amount) OVER win` により、前日の売上 `pre_amount` を取得します。  
  - `WINDOW win AS (ORDER BY sales_ymd)` により、`sales_ymd` の昇順で処理を行うよう指定します。  

- **最終的な出力を取得**  
  - `amount - pre_amount AS diff_amount` により、前日との差分 `diff_amount` を計算します。  
  - `ORDER BY sales_ymd` で日付順に並べ替えます。  
  - `LIMIT 10` により、最初の10件を取得します。  
