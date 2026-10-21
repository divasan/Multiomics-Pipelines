
#!/bin/bash
#SBATCH --job-name=CUTandRUN
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=220G
#SBATCH --time=3-00:00:00
#SBATCH --partition=standard
#SBATCH --output=cutandrun_%j.out
#SBATCH --error=cutandrun_%j.err

set -euo pipefail

# nf-core/cutandrun v3.2.2
# Nextflow 24.10.0
# CUT&RUN and CUT&Tag analysis

# Directory containing main.nf from nf-core/cutandrun v3.2.2
PIPELINE="/path/to/nf-core/cutandrun"

# Full path to the Nextflow executable
NEXTFLOW="/path/to/nextflow"

# Directory for results and intermediate files
BASE_DIR="/path/to/cutandrun_output"

# Reference genome FASTA (hg38.fa)
FASTA="/path/to/references/hg38.fa"

# Directory containing the hg38 Bowtie2 index files
BOWTIE2_DIR="/path/to/references/bowtie2"

# Gene annotation file (GENCODE GTF)
GTF="/path/to/references/gencode.annotation.gtf"

# ENCODE hg38 blacklist BED file
BLACKLIST="/path/to/references/hg38-blacklist.v2.bed.gz"

# Samplesheet
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLESHEET="${SCRIPT_DIR}/samplesheet.csv"

# Load software
module load java/17
module load apptainer

export NXF_VER=24.10.0
export NXF_HOME="${BASE_DIR}/nextflow_home"
export NXF_OPTS="-Xms1g -Xmx8g"

# Output directories
RESULTS_DIR="${BASE_DIR}/results"
WORK_DIR="${BASE_DIR}/work"
TMP_DIR="${BASE_DIR}/tmp"
CONFIG="${BASE_DIR}/local.config"

# Apptainer cache
export APPTAINER_CACHEDIR="${BASE_DIR}/apptainer/cache"
export APPTAINER_TMPDIR="${BASE_DIR}/apptainer/tmp"
export NXF_APPTAINER_CACHEDIR="${BASE_DIR}/apptainer/nxf_cache"
export TMPDIR="${TMP_DIR}"

mkdir -p \
    "${RESULTS_DIR}" \
    "${WORK_DIR}" \
    "${TMP_DIR}" \
    "${NXF_HOME}" \
    "${APPTAINER_CACHEDIR}" \
    "${APPTAINER_TMPDIR}" \
    "${NXF_APPTAINER_CACHEDIR}"

# Check input files
for file in "${PIPELINE}/main.nf" "${NEXTFLOW}" \
            "${SAMPLESHEET}" "${FASTA}" "${GTF}" "${BLACKLIST}"; do

    [[ -f "${file}" ]] || {
        echo "ERROR: Missing ${file}" >&2
        exit 1
    }
done

[[ -d "${BOWTIE2_DIR}" ]] || {
    echo "ERROR: Bowtie2 index directory not found" >&2
    exit 1
}

# Check software
"${NEXTFLOW}" -version
apptainer --version

# Local executor configuration
cat > "${CONFIG}" <<EOF
process {
    executor = 'local'
    resourceLimits = [
        cpus: 32,
        memory: 200.GB,
        time: 72.h
    ]
}

apptainer {
    autoMounts = true
    cacheDir = '${NXF_APPTAINER_CACHEDIR}'
    pullTimeout = '2h'
}
EOF

# Run nf-core/cutandrun
cd "${BASE_DIR}"

"${NEXTFLOW}" run "${PIPELINE}" \
    -profile apptainer \
    -c "${CONFIG}" \
    -work-dir "${WORK_DIR}" \
    --input "${SAMPLESHEET}" \
    --outdir "${RESULTS_DIR}" \
    --igenomes_ignore \
    --fasta "${FASTA}" \
    --bowtie2 "${BOWTIE2_DIR}" \
    --gtf "${GTF}" \
    --blacklist "${BLACKLIST}" \
    --mito_name chrM \
    --normalisation_mode CPM \
    --normalisation_binsize 1 \
    --use_control true \
    --peakcaller seacr,macs2 \
    --max_cpus 32 \
    --max_memory 200.GB \
    --max_time 72.h \
    --multiqc_title CUTandRUN_CUTandTAG

echo "=== PIPELINE FINISHED ==="
date
echo "Results: ${RESULTS_DIR}"

