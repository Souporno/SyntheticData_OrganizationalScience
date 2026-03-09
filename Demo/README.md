# Demo — Generating Synthetic Data with SDV (CTGAN)

This folder contains the Jupyter notebook and outputs for generating synthetic tabular data from an organizational employee survey dataset using **CTGAN** via the **SDV (Synthetic Data Vault)** library.

**Paper:** Wang, P., Loignon, A.C., Shrestha, S., Banks, G.C., & Oswald, F.L. (2025). Advancing Organizational Science Through Synthetic Data. *Journal of Business and Psychology, 40*, 771–797.

**Original repo:** https://github.com/wpengda/SyntheticData_OrganizationalScience

**R-based validation results:** https://github.com/Souporno/SyntheticData_OrganizationalScience/tree/main/TestAyC

---

## Files

| File | Description |
|---|---|
| `DemoCTGAN.ipynb` | Jupyter notebook for synthetic data generation |
| `conda.yml` | Conda environment with all dependencies |
| `Boston.csv` | Original demo dataset from the paper |

> **Note:** `synthetic_data.csv` is not included in this repo pending professor approval for public sharing of derived organizational data.

---

## Setup

### Step 1: Clone the Repository
```bash
git clone https://github.com/wpengda/SyntheticData_OrganizationalScience.git
cd SyntheticData_OrganizationalScience/Demo
```

### Step 2: Create and Activate the Conda Environment
The repo provides a `conda.yml` file with all dependencies pre-listed:
```bash
conda env create -n vsynth -f conda.yml
conda activate vsynth
```
This installs SDV and all required packages into an isolated environment called `vsynth`.

If Jupyter isn't installed in the vsynth environment, fix it with:
```bash
pip install jupyter
```
Then run:
```bash
jupyter notebook DemoCTGAN.ipynb
```
This will open in your browser.

If `openpyxl` is missing when reading Excel files:
```bash
source /opt/anaconda3/etc/profile.d/conda.sh
conda activate vsynth
pip install openpyxl
```

### Step 3: Handle PII (Personally Identifiable Information)
PII handling matters. Flag columns like `E-mail`, `First Name`, and employee ID fields as PII so SDV uses its anonymization engine (powered by Faker) rather than learning and reproducing real values.

---

## Key Concepts

### What is SDV?
**SDV (Synthetic Data Vault)** is an open-source Python library built specifically for generating synthetic tabular data. Originally created at MIT's Data to AI Lab in 2016 and now maintained by DataCebo, it supports multiple synthesizer models including CTGAN, GaussianCopula, and TVAE. It works with single tables, multiple connected tables, and sequential/time-series data.

For organizational research specifically, SDV is valuable because it lets researchers share and analyze data that statistically behaves like real employee data without ever exposing actual individuals.

### What is CTGAN?
**CTGAN** (Conditional Tabular GAN) is a neural network — specifically a Generative Adversarial Network (GAN) — designed for tabular data. Two key training parameters:

**Epochs** — how many times the model trains over your entire dataset. More epochs = more learning, but also more time and risk of overfitting.
- 1000 epochs = fast, rough
- 5000 epochs = slow, more refined

**Batch Size** — instead of feeding all your data at once, the model trains on small chunks. Batch size controls how big those chunks are.
- Smaller batches (200) = noisier but sometimes generalizes better
- Larger batches (500) = smoother but needs more memory

The notebook runs a **hyperparameter search** across 12 combinations (3 batch sizes × 4 epoch counts) and keeps whichever produces synthetic data closest to the original statistically. This is a brute-force approach to find the best settings for the specific dataset.

> ⚠️ This will take a long time on a Mac without a GPU — 12 models × up to 5000 epochs each.

### Column Encoding Principle
For best results with CTGAN, encode column types correctly before training:
- **Ordinal columns** (Likert scales, job levels) → encode as integers so CTGAN learns the ordering
- **Nominal columns** (Gender, Area, City) → leave as categorical, no natural order exists

Forcing a fake numeric order onto nominal data actively hurts quality.

---

## Data Preparation Note

The original dataset (Arquitectura y Concreto) had translation issues. The 5 Likert-scale culture questions were originally in Spanish and mistranslated inconsistently. The correct encoding is:

| Spanish | English | Encoded Value |
|---|---|---|
| Totalmente de acuerdo | Totally agree | 4 |
| De acuerdo | Agree | 3 |
| En desacuerdo | Disagree | 2 |
| Totalmente en desacuerdo | Totally disagree | 1 |

This is a clean 4-point scale with no neutral midpoint. Encoding these as ordinal numerics (1–4) before training improved the SDV overall quality score from 80.31% to 81.36%.

The `Communication - It works` column contains free-text open-ended responses and was excluded from numeric analysis — CTGAN treats it as unordered categorical and assigns values by frequency sampling rather than learning any semantic structure.

---

## Results

### Hyperparameter Search
The best model was **batch_size=500, epochs=3000** with a MAE score of **3.31** (lowest = best). Interestingly, more epochs didn't always help — 3000 beat 5000 for batch size 500, which is normal with GANs. They can overfit or destabilize with too much training.

To check where the model was saved:
```python
import os
print(os.getcwd())
```

### SDV Quality Report

**Overall Score: 81.36%** — solid quality for a GAN-based synthetic dataset, especially on a Mac without a GPU.

| Score | Interpretation |
|---|---|
| Above 0.90 | Excellent |
| 0.80 – 0.90 | Good |
| 0.70 – 0.80 | Acceptable / borderline |
| Below 0.70 | Poor |

Notable column scores:
- **Communication - It works: 0.55** — lowest score, expected given free-text content
- **PERFORMANCE: 0.84** — sits comfortably in the acceptable range
- **CulturaAyC columns: 0.87–0.96** — strong performance after Likert encoding

CTGAN needs to learn the full shape of continuous distributions (mean, spread, skewness, tails), which is harder than categorical columns. GANs sometimes get stuck generating only the most common values and ignoring the tails. For a methodology demo this is fine; for substantive PERFORMANCE-specific research, flag it as a limitation.

### Privacy Check
Zero overlapping rows between original and synthetic data (overlap ratio = 0). The synthetic dataset contains no exact copies of real records.

### Distribution Check (PERFORMANCE vs Years of Service)

Both real and synthetic data are heavily concentrated in the **PERFORMANCE 75–100 range**, meaning most employees at this company perform highly. The synthetic data learned this correctly.

**What it got right:**
- Overall performance range and concentration correctly learned
- Weak positive tenure-performance trend preserved in both datasets
- Data spread at 0–10 years looks visually similar

**What it got wrong:**
- Synthetic data generated low-performance outliers (cyan dots around PERFORMANCE 60–75 with Years of Service 20+) that don't match real patterns
- The bottom cluster (Years of Service = 0–2) is over-represented — too many synthetic points compressed at the very bottom, suggesting CTGAN over-learned the frequency of newer employees
- The tails and low-frequency regions aren't perfectly learned

**What improved after Likert encoding:** Compared to the pre-encoding run, the synthetic data now covers the full PERFORMANCE range more faithfully (0–100), including rare low-performance cases that the previous model underrepresented. The upper range (PERFORMANCE 80–100, Years of Service 5–25) shows much tighter overlap between real and synthetic points.

**Insight:** The real data suggests no clear relationship between tenure and performance. Long-serving employees don't consistently outperform newer ones. The synthetic data roughly preserves this, which is good. We'd flag the low-performance outlier generation and over-clustering at Years of Service = 0 as limitations for PERFORMANCE-specific or tenure-specific research.

---

## Alternative: GaussianCopula

For better numerical column fidelity (especially PERFORMANCE), consider swapping CTGAN for **GaussianCopula**, which models each numerical column's distribution explicitly using statistical methods rather than a neural network:

```python
from sdv.single_table import GaussianCopulaSynthesizer

synthesizer = GaussianCopulaSynthesizer(metadata)
synthesizer.fit(original_data)
synthetic_data = synthesizer.sample(len(original_data))
```

GaussianCopula is weaker at capturing complex relationships between columns but often outperforms CTGAN on individual column fidelity for smaller datasets with continuous numerical columns.

---

## Appendix: Why Ordinal Encoding Matters for CTGAN

When CTGAN receives text labels like `"Totally agree"`, it treats them as unordered categories and one-hot encodes them internally. It has no idea that `"Totally agree" > "Agree" > "Disagree"` — the ordinal relationship is completely lost. By encoding as 4, 3, 2, 1 before training, CTGAN learns that 4 is close to 3 and far from 1, allowing it to generate realistic intermediate patterns rather than just mimicking category frequencies.
