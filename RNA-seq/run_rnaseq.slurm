
#!/bin/bash
#SBATCH --job-name=RNAseq
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=370G
#SBATCH --time=5-00:00:00
#SBATCH --partition=standard
#SBATCH --output=rnaseq_%j.out
#SBATCH --error=rnaseq_%j.err

set -euo pipefail

# nf-core/rnaseq v3.18.0
# Nextflow 24.10.0
# STAR + RSEM

# Directory containing main.nf from nf-core/rnaseq v3.18.0
PIPELINE="/path/to/nf-core/rnaseq"

# Full path to the Nextflow executable
NEXTFLOW="/path/to/nextflow"

# Directory for results and intermediate files
BASE_DIR="/path/to/rnaseq_output"

# Reference genome FASTA (hg38.fa)
FASTA="/path/to/references/hg38.fa"

# Gene annotation file (GENCODE GTF)
GTF="/path/to/references/gencode.v50.annotation.gtf"

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

# Check required files
for file in "${PIPELINE}/main.nf" "${NEXTFLOW}" \
            "${SAMPLESHEET}" "${FASTA}" "${GTF}"; do

    [[ -f "${file}" ]] || {
        echo "ERROR: Missing ${file}" >&2
        exit 1
    }
done

# Check software
"${NEXTFLOW}" -version
apptainer --version

# Check samplesheet
header="$(head -n 1 "${SAMPLESHEET}")"
header="${header%$'\r'}"

[[ "${header}" == "sample,fastq_1,fastq_2,strandedness" ]] || {
    echo "ERROR: Incorrect samplesheet header" >&2
    exit 1
}

# Local executor configuration
cat > "${CONFIG}" <<EOF
process {
    executor = 'local'
    resourceLimits = [
        cpus: 32,
        memory: 350.GB,
        time: 120.h
    ]
}

apptainer {
    autoMounts = true
    cacheDir = '${NXF_APPTAINER_CACHEDIR}'
    pullTimeout = '2h'
}
EOF

# Run nf-core/rnaseq
cd "${BASE_DIR}"

"${NEXTFLOW}" run "${PIPELINE}" \
    -profile apptainer \
    -c "${CONFIG}" \
    -work-dir "${WORK_DIR}" \
    --input "${SAMPLESHEET}" \
    --outdir "${RESULTS_DIR}" \
    --igenomes_ignore \
    --fasta "${FASTA}" \
    --gtf "${GTF}" \
    --gencode \
    --aligner star_rsem \
    --save_align_intermeds \
    --save_reference \
    --max_cpus 32 \
    --max_memory 350.GB \
    --max_time 120.h \
    --multiqc_title RNAseq

echo "=== PIPELINE FINISHED ==="
date
echo "Results: ${RESULTS_DIR}"

