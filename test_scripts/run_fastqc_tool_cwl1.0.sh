#!/usr/bin/env bash

# Author: Jeffrey Grover
# Created: 09/2021
# Purpose: Run the fastqc_tool_cwl1.0 job for testing purposes

# Run this script to test a real workflow execution including its output

DATETIME=$(date +"%Y%m%d_%H%M%S")

cwltool --outdir "${DATETIME}_fastqc_tool_cwl1.0" \
  fastqc_tool_cwl1.0/fastqc_tool_cwl1.0.cwl \
  test_scripts/fastqc_tool_cwl1.0-job.yml