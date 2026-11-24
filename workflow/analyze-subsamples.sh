#!/bin/bash
# Generate subsampled reads, then run the whole pipeline on just the subsampled data.
# Run from the repository root: bash workflow/analyze-subsamples.sh
set -o errexit -o nounset -o xtrace

CORES="${CORES:-100}"
# For push notifications, add: --config ntfy_topic=my-topic (to both snakemake calls' --config)
SNAKEMAKE_ARGS=(--cores "$CORES" --use-conda --printshellcmds --rerun-incomplete --keep-going --rerun-triggers mtime)

# First, generate subsampled reads (if we need to)
# This validates md5sums and then runs seqtk to (stably) select up to 5M read pairs per sample (10M reads in total)
# This runs about 8 jobs in parallel, and takes roughly 8 hours to complete for melanoma (150 samples)
snakemake "${SNAKEMAKE_ARGS[@]}" --config make-subsampled=True

# Next, run the subsampled analyses
# This runs the entire analysis pipeline, exclusively on _subsampled data
snakemake "${SNAKEMAKE_ARGS[@]}" --config analyze-subsampled=True

# Run only md5sum -- runs once, very IO intensive:
#  snakemake --cores 100 --use-conda --printshellcmds --rerun-incomplete --keep-going --rerun-triggers mtime --until md5sum
# Run on everything (the full, non-subsampled data):
#  snakemake --cores 100 --use-conda --printshellcmds --rerun-incomplete --keep-going --rerun-triggers mtime

# NOTE: If you need, you can specify a temp directory, e.g. with:
# snakemake --cores 100 --use-conda --printshellcmds --rerun-incomplete --rerun-triggers mtime --keep-going --default-resources "tmpdir='/scratch-raid0/tmp/'"
