# TestAyC — Synthetic Data Validation for Arquitectura y Concreto

This folder contains the R-based validation analysis for synthetic data generated from an employee survey dataset from **Arquitectura y Concreto**, a Colombian construction company. The analysis adapts the four-test framework from Wang et al. (2025) to evaluate whether CTGAN-generated synthetic data is statistically representative of the original.

**Paper:** Wang, P., Loignon, A.C., Shrestha, S., Banks, G.C., & Oswald, F.L. (2025). Advancing Organizational Science Through Synthetic Data. *Journal of Business and Psychology, 40*, 771–797.

**Original author R script:** https://github.com/wpengda/SyntheticData_OrganizationalScience/blob/main/Study_one/Study1_analysis.R

**Full results and synthetic data generation:** https://github.com/Souporno/SyntheticData_OrganizationalScience/tree/main/TestAyC

---

## Files

| File | Description |
|---|---|
| `study_AyC.R` | R script implementing the 4 basic tests |
| `results_AyC.txt` | Full printed output from running the script |
| `plot_correlation_difference.png` | Histogram of absolute correlation differences |
| `plot_regression_scatter.png` | Scatter plot of PERFORMANCE vs Years of Service |

---

## Setup

### Step 1: Install R
Go to https://cran.r-project.org → Download R for macOS → install the .pkg

### Step 2: Install the R extension in VSCode
Open VSCode → Extensions (Cmd+Shift+X) → search "R" → install the one by **REditorSupport**

### Step 3: Install radian
```bash
source /opt/anaconda3/etc/profile.d/conda.sh
conda activate vsynth
pip install radian --break-system-packages
```
When prompted for a CRAN mirror, type `1` and press Enter — that's the 0-Cloud mirror which automatically picks the closest server.

### Step 4: Run the script
Open `study_AyC.R` in VSCode and press `Cmd+Shift+S` to source the full file.

---

## Dataset

The original dataset is an employee survey from Arquitectura y Concreto (n ≈ 716). Variables used in validation:

- **Years of Service** — continuous
- **CulturaAyC columns (5)** — ordinal Likert scale, encoded as 1–4:
  - Totally agree = 4, Agree = 3, Disagree = 2, Totally disagree = 1
- **PERFORMANCE** — continuous numeric (0–100)
- **AGE** — continuous
- **NPS company** — numeric (1–10)

Note: The `Communication - It works` column was excluded as it contains free-text open-ended responses and carries no numeric structure suitable for validation.

---

## The 4 Basic Tests

### Test 1: Overlapped Sample Test
Each row is hashed using MD5. The intersection of hash sets between original and synthetic data is computed.

**Result: Overlap Ratio = 0**

Zero rows in the synthetic dataset are identical to any row in the original. This confirms the synthetic data carries no direct privacy risk of re-identification through exact row matching.

---

### Test 2: Constrained Reflection Test
Descriptive statistics (min, max, median, mean, SD) are computed for each variable in both datasets, along with Cohen's d to measure mean differences. Benchmark: d < 0.20 = negligible.

| Variable | Cohen's d | Verdict |
|---|---|---|
| Years of Service | 0.208 | Acceptable |
| CulturaAyC - Add value | 0.309 | Moderate |
| CulturaAyC - Care for people | 0.157 | Negligible ✅ |
| CulturaAyC - Execute with discipline | 0.171 | Negligible ✅ |
| CulturaAyC - Promote teams | 0.244 | Moderate |
| CulturaAyC - Innovate | 0.195 | Negligible ✅ |
| PERFORMANCE | 0.239 | Moderate |
| AGE | 0.204 | Acceptable |
| NPS company | 0.218 | Acceptable |

Most variables fall in the negligible-to-small range. No variable exceeds d = 0.31, which is well within acceptable bounds for a GAN-based synthetic dataset. The synthetic data successfully reflects the original distributions at the univariate level.

---

### Test 3: Variable Correlation Test
Pearson correlation matrices are computed for both datasets. The absolute difference matrix is used to assess how well the synthetic data preserves inter-variable relationships.

**Results:**
- Mean absolute difference: **0.095**
- Standard deviation: 0.074
- Minimum difference: 0.000
- Maximum difference: 0.424

The histogram (`plot_correlation_difference.png`) shows the vast majority of correlation pairs differ by less than 0.20, with the distribution heavily concentrated near zero. There are 2 outlier pairs reaching ~0.44 difference, likely involving the Likert columns where CTGAN's categorical treatment affected joint distribution learning. Overall, a mean difference of ~0.10 indicates the synthetic data preserves the correlation structure of the original reasonably well.

---

### Test 4: Distribution Kurtosis and Skewness Test
Kurtosis and skewness are computed for each variable in both datasets to assess shape preservation.

| Variable | Kurtosis Original | Kurtosis Synthetic | Skewness Original | Skewness Synthetic |
|---|---|---|---|---|
| Years of Service | 6.50 | 10.62 | 1.78 | 2.52 |
| CulturaAyC - Add value | 5.04 | 4.66 | -1.18 | -1.20 |
| CulturaAyC - Care | 5.02 | 4.68 | -1.19 | -1.33 |
| CulturaAyC - Execute | 4.99 | 4.45 | -1.19 | -1.34 |
| CulturaAyC - Promote | 4.25 | 3.42 | -0.92 | -0.88 |
| CulturaAyC - Innovate | 5.63 | 4.94 | -1.44 | -1.46 |
| AGE | 2.54 | 2.63 | 0.55 | 0.52 |
| NPS company | 6.80 | 4.07 | -1.97 | -1.41 |

The Likert columns show excellent skewness preservation — synthetic values closely match original direction and magnitude. AGE is nearly perfect.

**Key concerns:**
- **Years of Service** — synthetic kurtosis (10.62) is notably higher than original (6.50). CTGAN over-concentrated values around the mode (new employees), a known GAN failure mode called **mode collapse**. Rare tenure values (15–25 years) are slightly underrepresented.
- **NPS company** — kurtosis divergence (6.80 vs 4.07). The original has a sharp spike at score = 10 which CTGAN smoothed out, spreading probability mass across 8, 9, 10 instead of concentrating it at 10.

---

## Regression Analysis (Supplementary)

The scatter plot (`plot_regression_scatter.png`) shows PERFORMANCE vs Years of Service for both original and synthetic data. Both datasets show a weak positive trend — longer-tenured employees score marginally higher. The synthetic regression line (red) starts slightly higher than the original (blue) at Year 0 but both converge toward ~92 by Year 25, indicating the directional relationship was preserved.

The synthetic data underrepresents rare low-performance cases (scores below 60), consistent with mode collapse toward the majority high-performance cluster.

---

## Subgroup Analysis Note

The AREA subgroup Cohen's d analysis produced `-Inf` values and empty results. This is because some AREA subgroups are very small (some departments have only 1 employee), making Cohen's d mathematically undefined. This is a known limitation of using a 30-category area variable for subgroup analysis on a dataset of ~716 rows.

---

## Overall Assessment

The synthetic data performs well across all four tests for a GAN-based model trained on a small organizational dataset (~716 rows) without GPU acceleration. It is suitable for methodology demonstration and research workflow prototyping. For substantive People Analytics research, the limitations around Years of Service tail underrepresentation and NPS peak flattening should be noted explicitly.
