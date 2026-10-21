
#!/bin/bash
#SBATCH --job-name=ENCODE_ATAC
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=04:00:00
#SBATCH --partition=standard
#SBATCH --output=atac_%j.out
#SBATCH --error=atac_%j.err

set -euo pipefail

# ENCODE ATAC-seq pipeline
# SLURM submission using Caper

# Directory containing atac.wdl from ENCODE-DCC/atac-seq-pipeline
PIPELINE_DIR="/path/to/atac-seq-pipeline"

# Full path to hg38.tsv containing ENCODE genome references
GENOME_TSV="/path/to/encode_references/hg38.tsv"

# Directory for results, input JSONs and logs
BASE_DIR="/path/to/atac_output"

# Load software
module load java/17
module load apptainer
export PATH="${HOME}/.local/bin:${PATH}"

# Input files
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLESHEET="${SCRIPT_DIR}/samplesheet.csv"
WDL="${PIPELINE_DIR}/atac.wdl"

# Output directories
JSON_DIR="${BASE_DIR}/input_jsons/${SLURM_JOB_ID}"
RUNS_DIR="${BASE_DIR}/samples"
LOG_DIR="${BASE_DIR}/logs"

# Check required files
for file in "${WDL}" "${GENOME_TSV}" "${SAMPLESHEET}"; do
    [[ -f "${file}" ]] || {
        echo "ERROR: Missing ${file}" >&2
        exit 1
    }
done

# Check software
for cmd in python3 caper java apptainer sbatch; do
    command -v "${cmd}" >/dev/null 2>&1 || {
        echo "ERROR: ${cmd} not found" >&2
        exit 1
    }
done

mkdir -p "${JSON_DIR}" "${RUNS_DIR}" "${LOG_DIR}"

echo "=== ENVIRONMENT ==="
date
hostname
caper --version
java -version
apptainer --version

# Generate ENCODE input JSONs
python3 "${SCRIPT_DIR}/generate_json.py" \
    "${SAMPLESHEET}" \
    "${GENOME_TSV}" \
    "${JSON_DIR}"

# Submit each sample through Caper
shopt -s nullglob
json_files=("${JSON_DIR}"/*.json)

if (( ${#json_files[@]} == 0 )); then
    echo "ERROR: No JSON files generated" >&2
    exit 1
fi

for json in "${json_files[@]}"; do

    sample="$(basename "${json}" .json)"
    sample_dir="${RUNS_DIR}/${sample}"

    mkdir -p "${sample_dir}"

    echo
    echo "=== SUBMITTING ${sample} ==="

    (
        cd "${sample_dir}"

        caper hpc submit "${WDL}" \
            -i "${json}" \
            --singularity \
            --leader-job-name "ATAC_${sample}"

    ) 2>&1 | tee "${LOG_DIR}/${sample}.submit.log"

done

echo
echo "=== ALL SUBMISSIONS FINISHED ==="
date

