# Independent color-difference reference values

`ciede2000.txt` contains the 34 numerical input/output pairs published by
Gaurav Sharma, Wencheng Wu, and Edul N. Dalal with “The CIEDE2000
Color-Difference Formula: Implementation Notes, Supplementary Test Data,
and Mathematical Observations,” *Color Research & Application* 30(1),
21–30 (2005), [doi:10.1002/col.20070](https://doi.org/10.1002/col.20070).

Source: [the authors' test-data page](https://hajim.rochester.edu/ece/sites/gsharma/ciede2000/)
and [plain-text data](https://hajim.rochester.edu/ece/sites/gsharma/ciede2000/dataNprograms/ciede2000testdata.txt),
retrieved September 15, 2026. Numeric rows are unchanged; a trailing blank line was removed. No MATLAB code,
spreadsheet, or paper text is included. The repository's MIT grant covers
Luke Steuber's original test harness; these reference measurements are
attributed to their authors.

Each row is `L1 a1 b1 L2 a2 b2 expected_delta_E_00`. The expected results are
rounded to four decimals, so the comparison tolerance is 0.00005. Both argument
orders are tested, including zero-chroma and hue-wrap cases.

These checks validate numerical implementation and current software behavior.
They do not establish clinical screening accuracy, display calibration, or
physical-device performance.
