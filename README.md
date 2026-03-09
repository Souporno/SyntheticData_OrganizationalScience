# Synthetic Data for Organizational Science — Fork by Souporno Ghosh

This is a fork of the replication repository for:

> Wang, P., Loignon, A.C., Shrestha, S., Banks, G.C., & Oswald, F.L. (2025). Advancing Organizational Science Through Synthetic Data. *Journal of Business and Psychology, 40*, 771–797.
> https://link.springer.com/article/10.1007/s10869-024-09997-w

**Original repository:** https://github.com/wpengda/SyntheticData_OrganizationalScience

---

## What This Fork Does

This fork adapts the paper's synthetic data generation and validation framework to a real organizational dataset — an employee survey from **Arquitectura y Concreto**, a Colombian construction company — as part of a People Analytics research project at the **University of Washington iSchool**.

The work is organized into two folders:

**`Demo/`** — Synthetic data generation using CTGAN via the SDV library. Adapts the original notebook to the AyC dataset, including proper Likert-scale ordinal encoding and PII handling. See the [Demo README](Demo/README.md) for setup and results.

**`TestAyC/`** — R-based validation of the synthetic data using the four-test framework from Wang et al. (2025): Overlapped Sample Test, Constrained Reflection Test, Distribution Kurtosis and Skewness Test, and Variable Correlation Test. See the [TestAyC README](TestAyC/README.md) for full results.

---

## Framework

This fork demonstrates the **Exploratory → Confirmatory** research model described in Wang et al. (2025):

- The research team conducts exploratory analysis on synthetic data only
- The partner organization runs confirmatory validation on real data internally
- Raw employee data never leaves the organization

This approach supports open science collaboration while protecting employee privacy and proprietary organizational information.

---

## Affiliation

People Analytics Lab | University of Washington Information School

PI: Dr. Heather Whiteman
