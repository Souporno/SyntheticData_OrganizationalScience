# Leveraging Synthetic Data to Advance Organizational Research

Welcome to the GitHub repository for "Leveraging Synthetic Data to Advance Organizational Science." This repository is structured to facilitate an understanding and exploration of the research presented in our article.

- **Study_one**: Analysis of the first part of our study, for GATB data.
- **Study_two**: Analysis of the second part of our study, for CCL leadership data.
- **Demo**: Code demo for generating synthetic data.

Regarding data sharing, as mentioned in our paper, synthetic data is a promising method in organizational research, but it still requires further development. Our paper serves as a case in point, illustrating that we cannot share the original datasets nor the synthetic datasets derived from them, as this would violate our existing data management policies. However, we are hopeful that synthetic data will be shared in the future as its acceptance in organizational research increases and technology advances. This is the central point of our paper.

Although we cannot share data, we will share all analysis code and demonstrations for generating synthetic data.

For specific data inquiries, please contact the [National Center for O*NET Development](https://www.onetcenter.org/) regarding the GATB dataset, and the [Center for Creative Leadership](https://www.ccl.org/) regarding the CCL dataset.

> **Privacy disclaimer:** The original dataset and the resulting synthetic dataset used in the Demo have not been included in this repository to protect individual privacy and comply with data management policies.

---

## Demo: Step-by-Step Guide to Generating Synthetic Data with SDV

The following documents learnings and findings from running the demo with a real-world organizational dataset using the [SDV (Synthetic Data Vault)](https://github.com/sdv-dev/SDV) library.

### Step 1 — Clone the Repository

Open your system Terminal:

```bash
git clone https://github.com/wpengda/SyntheticData_OrganizationalScience.git
cd SyntheticData_OrganizationalScience/Demo
```

### Step 2 — Create and Activate the Conda Environment

The repo provides a `conda.yml` file with all dependencies pre-listed:

```bash
conda env create -n vsynth -f conda.yml
conda activate vsynth
```

This installs SDV and all required packages into an isolated environment called `vsynth`.

If Jupyter is not installed in the `vsynth` environment, install it manually:

```bash
pip install jupyter
```

Then launch the notebook:

```bash
jupyter notebook demo.ipynb
```

> **Note:** If `conda` is not found in your terminal (common on macOS), initialize it first:
> ```bash
> source /opt/anaconda3/etc/profile.d/conda.sh
> conda activate vsynth
> ```

If your dataset is an Excel file (`.xlsx`) rather than a CSV, also install `openpyxl`:

```bash
pip install openpyxl
```

---

### Step 3 — PII (Personally Identifiable Information) Handling

PII handling is critical. Columns containing personally identifiable information — such as full names, first names, and email addresses — must be explicitly flagged so SDV uses its anonymization engine (powered by [Faker](https://faker.readthedocs.io/)) to generate fake but realistic replacements instead of modeling the real values.

```python
metadata.update_column(table_name='employees', column_name='Yam', sdtype='name', pii=True)
metadata.update_column(table_name='employees', column_name='First Name', sdtype='first_name', pii=True)
metadata.update_column(table_name='employees', column_name='E-mail', sdtype='email', pii=True)
```

Without these flags, SDV may attempt to statistically model and reproduce actual names and emails, which defeats the purpose of anonymization.

> **Note on the `Metadata` class:** As of SDV 1.34+, `SingleTableMetadata` is deprecated. Use the new `Metadata` class instead, calling `detect_from_dataframe` as a class method:
> ```python
> from sdv.metadata import Metadata
> metadata = Metadata.detect_from_dataframe(data=original_data, table_name='employees')
> ```

---

### Step 4 — Understanding Batch Size and Epochs

CTGAN (Conditional Tabular GAN) is a neural network — specifically a Generative Adversarial Network (GAN) designed for tabular data. The demo loops over combinations of two key training parameters:

**Epochs** — how many times the model trains over your entire dataset. More epochs = more learning, but also more time and risk of overfitting.
- 1,000 epochs = fast, rough
- 5,000 epochs = slow, more refined

**Batch Size** — instead of feeding all data at once, the model trains on small chunks. Batch size controls how big those chunks are.
- Smaller batches (200) = noisier updates, but sometimes generalizes better
- Larger batches (500) = smoother updates, but requires more memory

**Why loop over combinations?** The code performs a basic hyperparameter search — trying all 12 combinations (3 batch sizes × 4 epoch counts) and keeping whichever produces synthetic data statistically closest to the original. It is a brute-force way to find the best settings for a specific dataset.

> **Performance note:** This will take a very long time on a Mac without a GPU — 12 models × up to 5,000 epochs each. For a quick test, reduce the search space first:
> ```python
> batch_sizes = [500]
> epochs_list = [300]
> ```

**Best model from our run:** `batch_size=500, epochs=3000` with a mean absolute error score of **5.74** (lower is better). Interestingly, more epochs did not always help — 3,000 epochs beat 5,000 for batch size 500, which is normal with GANs. They can overfit or destabilize with too much training.

---

### Step 5 — Evaluating Synthetic Data Quality

#### Diagnostic (Structure & Validity)

```python
from sdv.evaluation.single_table import run_diagnostic
diagnostic = run_diagnostic(real_data=original_data, synthetic_data=synthetic_data, metadata=metadata)
```

Our run achieved **100% on both Data Validity and Data Structure** — confirming the synthetic data is well-formed and structurally identical to the original.

#### Quality Report (Statistical Similarity)

```python
from sdv.evaluation.single_table import evaluate_quality
quality_report = evaluate_quality(real_data=original_data, synthetic_data=synthetic_data, metadata=metadata)
```

Our run results:

| Metric | Score |
|---|---|
| Column Shapes | 86.97% |
| Column Pair Trends | 73.64% |
| **Overall** | **80.31%** |

**General benchmarks from the SDV literature:**

| Score | Interpretation |
|---|---|
| Above 0.90 | Excellent |
| 0.80 – 0.90 | Good |
| 0.70 – 0.80 | Acceptable / borderline |
| Below 0.70 | Poor |

An overall score of **80.31%** is solid quality for a GAN-based synthetic dataset, especially when running on a Mac without a GPU.

**Notable finding — Communication column (0.53):** This column scored lowest, likely because it contains long free-text responses with many NaN values, which CTGAN struggles to model well.

---

### Step 6 — Why Numerical Columns Are Harder

Numerical columns like PERFORMANCE can take any value across a continuous range (e.g., 87.5, 99.17, 80.83). CTGAN needs to learn the full shape of the distribution — mean, spread, skewness, and tails — which is significantly harder than learning category proportions.

Specific challenges:
- **Mode collapse** — GANs can get "stuck" generating only common values and ignoring rare but real scores (very high or very low performance)
- **Multimodal distributions** — multiple peaks are difficult to learn
- **Decimal precision** — values like 99.167 are harder to replicate than whole numbers

Our PERFORMANCE column scored **0.77**, placing it in the acceptable-but-borderline range. For a methodology demo this is fine. For substantive People Analytics research on PERFORMANCE specifically, this should be flagged as a limitation, and validation on real data is recommended — consistent with the pre-registration framework proposed in this paper.

**Learning — consider GaussianCopula for numerical columns:**

GaussianCopula models each numerical column's distribution explicitly using statistical methods rather than neural networks, and often outperforms CTGAN on smaller datasets with continuous numerical columns:

```python
from sdv.single_table import GaussianCopulaSynthesizer

synthesizer = GaussianCopulaSynthesizer(metadata)
synthesizer.fit(original_data)
synthetic_data = synthesizer.sample(len(original_data))
```

The tradeoff is that GaussianCopula is weaker at capturing complex relationships *between* columns. For individual column fidelity, however, it is likely the better choice for datasets with important continuous numerical variables like PERFORMANCE.

---

### Step 7 — Privacy Verification

```python
overlapping_data = pd.merge(original_data, synthetic_data, how='inner')
print(overlapping_data)
```

**Result: Empty DataFrame** — zero overlapping rows between the original and synthetic datasets. No real individual's data was reproduced exactly. This demonstrates the core value of synthetic data for organizational research: analytical utility without privacy risk, directly supporting the methodology proposed in this paper.

---

### Step 8 — Visualizing Column Pair Distributions

```python
from sdv.evaluation.single_table import get_column_pair_plot

fig = get_column_pair_plot(
    real_data=original_data,
    synthetic_data=synthetic_data,
    metadata=metadata,
    column_names=['PERFORMANCE', 'Years of Service'],
)
fig.show()
```

> **Note:** `get_column_pair_plot` accepts exactly two column names. To compare multiple pairs, call it separately for each.

**Interpretation of PERFORMANCE vs. Years of Service:**

Both real and synthetic data are heavily concentrated in the PERFORMANCE 75–100 range, meaning most employees perform highly. The synthetic data learned this pattern correctly.

Areas where synthetic data fell short:
- Low-performance outliers (PERFORMANCE 25–50) were generated in the synthetic data without corresponding real counterparts
- Employees with very short tenure (Years of Service = 0–1) were over-represented in the synthetic output

**People Analytics insight:** The real data suggests no clear relationship between tenure and performance — long-serving employees do not consistently outperform newer ones. The synthetic data roughly preserves this finding, which is encouraging for methodology validation purposes.
