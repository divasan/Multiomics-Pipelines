#!/usr/bin/env python3

import csv
import json
import sys
from collections import defaultdict
from pathlib import Path

# Input files and output directory
samplesheet = sys.argv[1]
genome_tsv = sys.argv[2]
json_dir = Path(sys.argv[3])

json_dir.mkdir(parents=True, exist_ok=True)

# Read samplesheet and group biological replicates
samples = defaultdict(lambda: defaultdict(lambda: {"R1": [], "R2": []}))

with open(samplesheet, newline="") as f:
    for row in csv.DictReader(f):
        sample = row["sample"]
        rep = int(row["replicate"])

        r1 = Path(row["fastq_1"])
        r2 = Path(row["fastq_2"])

        # Check FASTQ files
        if not r1.is_file() or not r2.is_file():
            sys.exit(f"Missing FASTQ files for {sample}")

        samples[sample][rep]["R1"].append(str(r1.resolve()))
        samples[sample][rep]["R2"].append(str(r2.resolve()))

# Generate one JSON per sample
for sample, replicates in samples.items():

    data = {
        "atac.title": sample,
        "atac.pipeline_type": "atac",
        "atac.paired_end": True,
        "atac.align_only": False,
        "atac.true_rep_only": False,
        "atac.genome_tsv": str(Path(genome_tsv).resolve())
    }

    # Add FASTQs for each biological replicate
    for rep, fastqs in sorted(replicates.items()):
        data[f"atac.fastqs_rep{rep}_R1"] = fastqs["R1"]
        data[f"atac.fastqs_rep{rep}_R2"] = fastqs["R2"]

    # Save JSON
    output = json_dir / f"{sample}.json"

    with open(output, "w") as f:
        json.dump(data, f, indent=2)

    print(f"Generated {output}")

