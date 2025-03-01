以下、全ての「解説」セクションを追加しました。

---

## R (データフレーム操作)

### 解答例(1){#r-df1}

#### 解説

1. **`df_rec`：顧客データのフィルタリングと選択**  
   - `df_receipt` データフレームから、`customer_id` が "Z" で始まらないレコードをフィルタリングします。これにより、不正な顧客IDを排除しています。  
   - 必要な列 (`customer_id`, `sales_ymd`, `amount`) を選択し、`customer_id` ごとにグループ化します。

2. **`df_date`：顧客ごとの購入日数の集計と上位20件の抽出**  
   - `df_rec` から各顧客ごとの売上日数（`n_date`）を計算します。`n_distinct(sales_ymd)` は、顧客ごとの異なる売上日の数をカウントします。  
   - `slice_max(n_date, n = 20, with_ties = TRUE)` により、売上日数が多い上位20顧客を抽出します。売上日数が同じ場合、複数の顧客が選ばれる可能性があります。

3. **`df_amount`：顧客ごとの売上合計金額の集計と上位20件の抽出**  
   - `df_rec` から各顧客ごとの合計金額（`sum_amount`）を計算します。`sum(amount)` によって顧客ごとの売上金額を合計します。  
   - `slice_max(sum_amount, n = 20, with_ties = TRUE)` により、合計金額が高い上位20顧客を抽出します。

4. **`df_date` と `df_amount` の統合およびソート**  
   - `full_join()` を使用して、`df_date` と `df_amount` を `customer_id` 列で結合します。これにより、売上日数と合計金額の両方の情報を持つデータが得られます。  
   - 最後に、`arrange()` を使って、売上日数と合計金額の降順でデータを並べ替え、`customer_id` で最終的にソートします。

### 解答例(2){#r-df2}

#### 解説

こちらの解答例も基本的に `df_receipt` データフレームを操作していますが、上記の解答例とは異なり、`slice_max()` ではなく、`arrange()` と `head(20)` を使って上位20顧客を抽出しています。

この解答例では、顧客ごとの売上日数（`n_date`）と合計金額（`sum_amount`）を計算し、上位20顧客を抽出して、両者の情報を統合したデータを表示しています。主な違いとして、`slice_max()` の代わりに `arrange()` と `head()` を使用しています。

2. **`df_date = df_rec %>% summarise(n_date = n_distinct(sales_ymd)) %>% arrange(desc(n_date), customer_id) %>% head(20)`**:
   - `df_rec` から顧客ごとの売上日数（`n_date`）を計算します。`n_distinct(sales_ymd)` によって、顧客ごとの異なる販売日の数をカウントします。
   - `arrange(desc(n_date), customer_id)` で、売上日数の降順に並べ替えます。その後、`head(20)` を使用して、上位20顧客を抽出します。

3. **`df_amount = df_rec %>% summarise(sum_amount = sum(amount)) %>% arrange(desc(sum_amount), customer_id) %>% head(20)`**:
   - `df_rec` から顧客ごとの合計金額（`sum_amount`）を計算します。`sum(amount)` によって、顧客ごとの売上金額を合計します。
   - `arrange(desc(sum_amount), customer_id)` で、合計金額の降順に並べ替えた後、`head(20)` で上位20顧客を抽出します。

この手法では、`slice_max()` の代わりに `arrange()` と `head()` を組み合わせて上位20顧客を抽出しています。`slice_max()` と比較して、より直感的に上位の値を取り出すことができ、可読性の高いコードとなります。

このアプローチは、`slice_max()` を使わずに上位顧客を抽出したい場合に有効です。

## R (データベース操作)

### 解答例(1){#r-db1}

#### 解説

この解答例では、`db_receipt` を使用して、SQLライクな操作でデータを処理しています。`%LIKE%` は SQL の `LIKE` 演算子と同じ役割を果たし、顧客IDが「Z」で始まるものを除外しています。その後、顧客ごとに売上日数と合計金額を計算します。

### 解答例(2){#r-db2}

#### 解説

こちらの解答例も、データベース操作に関する内容ですが、`slice_max()` ではなく、`arrange()` と `head()` を使用して、上位20顧客を取得しています。

この方法でも、上位顧客を抽出するための効率的な手段を提供しています。データベース操作をRで行いたい場合に、`arrange()` と `head()` を使用することは有効です。

## SQL

### 解答例(1)

#### 解説

このSQLクエリは、顧客ごとに売上日数と合計売上を基に、上位20顧客を抽出し、その情報を結合して結果を表示するものです。主なステップごとに説明します。

1. **CTE (共通テーブル式) `purchase_data`**
   - `receipt` テーブルから、`customer_id` が 'Z' で始まる顧客を除外したデータを取得します。これにより、不必要な顧客のデータを除外します。
   - `customer_id`, `sales_ymd`, `amount` の3つのカラムを選択します。

   ```sql
   WITH purchase_data AS (
     SELECT 
       customer_id, sales_ymd, amount
     FROM receipt
     WHERE customer_id NOT LIKE 'Z%'
   )
   ```

2. **CTE `customer_purchase_dates`**
   - `purchase_data` から、顧客ごとの異なる売上日数をカウントします（`COUNT(DISTINCT sales_ymd)`）。`n_date` という名前で保存し、顧客ごとに集計します。
   - `GROUP BY customer_id` で、顧客ごとに集計を行っています。

   ```sql
   customer_purchase_dates AS (
     SELECT 
       customer_id, 
       CAST(COUNT(DISTINCT sales_ymd) AS INTEGER) AS n_date
     FROM purchase_data
     GROUP BY customer_id
   )
   ```

3. **CTE `ranked_purchase_dates`**
   - `customer_purchase_dates` のデータに対して、`RANK()` 関数を使用して、売上日数 `n_date` に基づいてランク付けを行います。降順で並べ、売上日数が多い顧客に低いランク（1位）を付けます。
   - `RANK()` によって、売上日数が同じ顧客には同じランクが付けられます。

   ```sql
   ranked_purchase_dates AS (
     SELECT 
       customer_id, 
       n_date, 
       RANK() OVER (ORDER BY n_date DESC) AS rank_n_date
     FROM customer_purchase_dates
   )
   ```

4. **CTE `customer_total_sales`**
   - `purchase_data` から顧客ごとの合計売上金額（`SUM(amount)`）を計算します。
   - `GROUP BY customer_id` で顧客ごとに売上金額を集計します。

   ```sql
   customer_total_sales AS (
     SELECT 
       customer_id, 
       SUM(amount) AS sum_amount
     FROM purchase_data
     GROUP BY customer_id
   )
   ```

5. **CTE `ranked_total_sales`**
   - `customer_total_sales` のデータに対して、`RANK()` 関数を使用して、売上金額 `sum_amount` に基づいてランク付けを行います。売上金額が多い顧客に低いランク（1位）を付けます。
   - 同じく、`RANK()` によって、売上金額が同じ顧客には同じランクが付けられます。

   ```sql
   ranked_total_sales AS (
     SELECT 
       customer_id, 
       sum_amount, 
       RANK() OVER (ORDER BY sum_amount DESC) AS rank_sum_amount
     FROM customer_total_sales
   )
   ```

6. **CTE `top_customers_by_dates`**
   - `ranked_purchase_dates` のデータから、上位20顧客（`rank_n_date <= 20`）を抽出します。売上日数に基づいてランクが高い（多い）顧客を選びます。

   ```sql
   top_customers_by_dates AS (
     SELECT customer_id, n_date
     FROM ranked_purchase_dates
     WHERE rank_n_date <= 20
   )
   ```

7. **CTE `top_customers_by_sales`**
   - `ranked_total_sales` のデータから、上位20顧客（`rank_sum_amount <= 20`）を抽出します。売上金額に基づいてランクが高い顧客を選びます。

   ```sql
   top_customers_by_sales AS (
     SELECT customer_id, sum_amount
     FROM ranked_total_sales
     WHERE rank_sum_amount <= 20
   )
   ```

8. **最終的な選択と結合**
   - `top_customers_by_dates` と `top_customers_by_sales` を `FULL JOIN` で結合します。これにより、売上日数または売上金額のいずれかに基づいて上位に位置する顧客が表示されます。`COALESCE(d.customer_id, s.customer_id)` を使用して、`customer_id` が両方のテーブルに存在する場合に正しく結合します。
   - 最後に、売上日数と売上金額を降順で並べ替えます（`ORDER BY n_date DESC, sum_amount DESC, customer_id`）。

   ```sql
   SELECT 
     COALESCE(d.customer_id, s.customer_id) AS customer_id,
     d.n_date,
     s.sum_amount
   FROM top_customers_by_dates d
   FULL JOIN top_customers_by_sales s
   USING (customer_id) 
   ORDER BY n_date DESC, sum_amount DESC, customer_id
   ```

### 解答例(2)

#### 解説

- **CTE `purchase_data`**  
  `receipt` テーブルから、`customer_id` が 'Z%' で始まらないレコードを抽出し、`customer_id`（顧客ID）、`sales_ymd`（販売日）、`amount`（販売金額）を選択します。このステップで不必要な顧客（IDが 'Z%' で始まる）を除外しています。

- **CTE `top_customers_by_dates`**  
  `purchase_data` CTEを基に、各顧客の異なる売上日数（`n_date`）をカウントします。`COUNT(DISTINCT sales_ymd)` を使用して、顧客ごとの異なる販売日の数を集計し、その結果を `n_date` として格納します。その後、`n_date` を降順で並べ替え、上位 20 人の顧客を `LIMIT 20` で抽出します。

- **CTE `top_customers_by_sales`**  
  `purchase_data` CTEを基に、各顧客の総販売金額（`sum_amount`）を集計します。`SUM(amount)` を使用して顧客ごとの販売金額の合計を算出し、`sum_amount` を降順に並べ替え、上位 20 人の顧客を `LIMIT 20` で抽出します。

- **最終選択**  
  `top_customers_by_dates` と `top_customers_by_sales` の結果を `FULL JOIN` で結合し、顧客ごとの売上日数（`n_date`）と総販売金額（`sum_amount`）を表示します。`COALESCE(d.customer_id, s.customer_id)` を使用して、片方のテーブルにしか存在しない顧客IDも含めて結果を取得します。その後、`n_date`（売上日数）と `sum_amount`（総販売金額）の降順で並べ替え、顧客IDで昇順に整列します。
