---
name: "Report Bug"
about: Report a bug to help us improve the R-Zoo rectilinear floorplan benchmark dataset and tools.
title: "[BUG] "
labels: bug
assignees: ""
---

# Bug Report

## Description of the Issue
A clear and concise description of what went wrong.

Example:  
“Running `modify_def.py` on the Ariane133 benchmark produced an invalid DIEAREA polygon in the output DEF file.”

---

## Steps to Reproduce
Please provide a minimal reproducible example.

1. Command used:
```py
python3 modify_def.py --input <path> --output <path> --config <file>
```

2. Input design:
- [ ] DEF file  
- [ ] LEF file  
- [ ] Verilog sources  
- [ ] Floorplan image (for CV Recognition mode)
3. Additional notes if needed.

---

## Expected Behavior
Describe what you expected to happen.

Example:  
“The script should generate a valid rectilinear DIEAREA with no self-intersection or overlapping cutouts.”

---

## Actual Behavior
Describe what actually happened.

Example:  
“The generated DIEAREA contains a non-manhattan segment and DREAMPlace failed during global placement.”

---

## Environment Information
Please fill in all applicable fields:

- OS:  
- Python version:  
- Commit hash / Release tag:  
- Mode used:  
- [ ] Rectilinear Generation  
- [ ] DEF Modification  
- [ ] CV Recognition (image → def)  
- Dependencies version (if modified):  
- numpy  
- shapely  
- matplotlib  
- opencv-python  

---

## Attachments (Highly Recommended)
Please attach relevant files that help reproduce the issue:

- Error logs  
- Console output  
- DEF/LEF snippets  
- Generated plots (`floorplan_plots/`)  
- Input image (if using CV Recognition mode)  
- JSON config file  
- Screenshots

---

## Additional Notes
Any extra information, hypothesis, or context that might help diagnose the problem.

