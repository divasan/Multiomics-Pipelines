## ATAC-seq

ATAC-seq data is processed using the [ENCODE ATAC-seq pipeline](https://github.com/ENCODE-DCC/atac-seq-pipeline) with Caper and SLURM.

### Files

- `ATAC-seq/samplesheet.csv` – Sample names, biological replicates, and paired-end FASTQ paths.
- `ATAC-seq/generate_json.py` – Generates the ENCODE input JSON files from the samplesheet.
- `ATAC-seq/run_atac.sh` – Submits the samples to the ENCODE pipeline using Caper and SLURM.

### Requirements

- ENCODE ATAC-seq pipeline
- Caper, Java, Python 3, and Apptainer
- SLURM scheduler
- Genome reference files and the corresponding `hg38.tsv` for hg38 analysis

### Running the pipeline

**1.** Clone the ENCODE ATAC-seq pipeline:

```bash
git clone https://github.com/ENCODE-DCC/atac-seq-pipeline.git
```

**2.** Set up Caper with the SLURM backend and prepare the genome reference files following the [ENCODE documentation](https://github.com/ENCODE-DCC/atac-seq-pipeline).

**3.** Edit `ATAC-seq/samplesheet.csv` with the sample names, replicate numbers, and full paths to the FASTQ files. Samples with multiple biological replicates should have separate rows with the same sample name.

**4.** Update the paths at the beginning of `run_atac.sh`:

- `PIPELINE_DIR` – Directory containing the ENCODE `atac.wdl` file.
- `GENOME_TSV` – Full path to the genome reference TSV file (`hg38.tsv`).
- `BASE_DIR` – Directory where the results will be saved.

**5.** Submit the pipeline from the `ATAC-seq` directory on the HPC:

```bash
sbatch run_atac.sh
```

The script generates one input JSON per sample, groups biological replicates within the same experiment, and submits the workflows through Caper. Results and logs are saved in the specified output directory.
