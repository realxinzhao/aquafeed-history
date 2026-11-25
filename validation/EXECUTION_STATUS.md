# Updated-data execution status

The full pipeline was run in native R 4.6.0 on Windows on November 25, 2026:
**75/75 checks passed**. A separate invocation of the compatibility exporter also passed
**56/56 checks**. The full pipeline checks production conservation, applied-crosswalk
coverage, the 2023-to-2024 coefficient hold, numerical coefficient fixtures through 2023,
and both compact GCAM export formats.

The default production panel contains 92,128 records for 1973–2024, with 770 production
codes; the applied species coefficient table contains 778 codes, including 8 legacy-only
reference codes. FAO FISHSTAT data were processed by gcamfaostat (archive release 2026.1.0).
2024 uses 2023 coefficients held forward and has no independent 2024 feed benchmark here.

The earlier 18 November 2026 exporter integration results in
`validation/export_integration_R_checks.csv` predate the FISHSTAT production refresh.
They document that earlier code revision and are not a substitute for the latest run.
