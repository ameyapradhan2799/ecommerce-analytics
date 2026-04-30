# E-commerce Sales & Customer Behaviour Dashboard

**Domain:** Retail / E-commerce &nbsp;|&nbsp; **Tools:** Python · SQL · Power BI &nbsp;|&nbsp; **Dataset:** [Olist Brazilian E-Commerce (Kaggle)](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

---

## Problem Statement

A Brazilian e-commerce platform wants to understand what drives revenue, how customers behave, what affects satisfaction, and whether delivery performance varies across segments. This project analyses 100,000+ orders to surface actionable insights for the business, marketing, and logistics teams.

---

## Project Structure

```
ecommerce-analytics/
├── data/
│   ├── raw/                    ← original Kaggle CSVs (9 files)
│   └── processed/              ← cleaned outputs & chart exports
├── notebooks/
│   ├── 01_eda.ipynb            ← exploratory data analysis
│   ├── 02_feature_engineering.ipynb  ← RFM scoring, CLV, churn flags
│   └── 03_hypothesis_testing.ipynb   ← statistical hypothesis tests
├── sql/
│   ├── schema.sql              ← table creation & loading
│   └── rfm_segmentation.sql    ← RFM queries & customer segments
├── dashboard/
│   └── ecommerce_dashboard.pbix  ← Power BI file
└── README.md
```

---

## Key Findings

| Metric | Value |
|--------|-------|
| Total delivered orders | ~96,500 |
| Date range | Sep 2016 – Sep 2018 |
| Peak revenue month | Nov 2017 (Black Friday effect) |
| Most common payment | Credit card (74% of revenue) |
| Avg review score | 4.07 / 5 |
| Late delivery rate | ~8% |
| Top state by orders | São Paulo (SP) |

---

## Hypothesis Testing

Four business hypotheses were tested using industry-standard non-parametric statistical methods (α = 0.05). Non-parametric tests were chosen because review scores (ordinal) and revenue data (right-skewed) do not meet the normality assumption required for t-tests and ANOVA.

| # | Hypothesis | Test | Result | Key Finding |
|---|-----------|------|--------|-------------|
| H1 | Mean review score of late deliveries = mean review score of on-time deliveries | Mann-Whitney U | **H₀ Rejected** | Late orders score ~0.4 pts lower on average (p < 0.05) |
| H2 | Mean order value is the same across all payment types | Kruskal-Wallis + Dunn post-hoc | **H₀ Rejected** | Credit card users spend ~40% more than boleto users (p < 0.05) |
| H3 | Review score distribution is independent of product category | Chi-square + Cramér's V | **H₀ Rejected** | Category and satisfaction are related; Cramér's V ≈ 0.08 (small but real effect) |
| H4 | Mean delivery time for weekend orders = mean delivery time for weekday orders | Mann-Whitney U | **H₀ Rejected** | Weekend orders take ~1 extra day on average (p < 0.05) |

> All four null hypotheses were rejected, confirming that delivery performance, payment behaviour, and product category are all statistically significant drivers of customer experience.

---

## Analytical Approach

**Phase 1 — EDA** (`01_eda.ipynb`)
Loaded and cleaned all 9 Olist tables. Parsed datetime columns, handled nulls, and built 8 exploratory charts covering revenue trends, order timing, top categories, payment types, review scores, delivery delays, and geography.

**Phase 2 — Feature Engineering** (`02_feature_engineering.ipynb`)
Computed RFM scores (Recency, Frequency, Monetary), CLV estimates, churn flags (no order in 90 days), and delivery delay metrics. Loaded results into SQLite for RFM segmentation queries.

**Phase 3 — Hypothesis Testing** (`03_hypothesis_testing.ipynb`)
Tested four hypotheses using Mann-Whitney U, Kruskal-Wallis, and Chi-square tests from `scipy.stats`. Computed effect sizes (Cramér's V, rank-biserial correlation) alongside p-values to quantify practical significance, not just statistical significance.

**Phase 4 — Power BI Dashboard**
Built an executive dashboard with KPI cards (revenue, AOV, churn %, late delivery %), monthly trend chart, RFM segment breakdown, and state-level map. Slicers for category, state, and date range.

---

## How to Run

```bash
# 1. Clone the repo
git clone https://github.com/YOUR_USERNAME/ecommerce-analytics.git
cd ecommerce-analytics

# 2. Install dependencies
pip install pandas numpy matplotlib seaborn scipy scikit-posthocs sqlalchemy jupyter

# 3. Download dataset
# Go to https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
# Place all CSVs in data/raw/

# 4. Run notebooks in order
# 01_eda.ipynb → 02_feature_engineering.ipynb → 03_hypothesis_testing.ipynb

# 5. Open dashboard
# Open dashboard/ecommerce_dashboard.pbix in Power BI Desktop
```

---

## Skills Demonstrated

`Pandas` `NumPy` `Matplotlib` `Seaborn` `SciPy` `Hypothesis Testing` `Mann-Whitney U` `Chi-square` `Kruskal-Wallis` `Effect Size` `SQL` `RFM Segmentation` `Power BI` `DAX` `ETL` `Data Cleaning` `EDA`
