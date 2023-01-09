#!/bin/bash
set -o xtrace

# First, generate subsampled reads (if we need to)
# This validates md5sums and then runs seqtk to (stably) select 5M reads/paired end (max) = total 10M paired reads
# This runs about 8 jobs in parallel, and takes roughly 8 hours to complete for melanoma (150 samples)
snakemake --cores 100 --use-conda --printshellcmds --rerun-incomplete --keep-going --rerun-triggers mtime --until seqtk_subsample

# Next, run the subsampled analyses
# This runs the entire analysis pipeline, exclusively on _subsampled data
snakemake --cores 100 --use-conda --printshellcmds --rerun-incomplete --keep-going --rerun-triggers mtime --config subsampled=True

# Run only md5sum -- runs once, very IO intensive:
#  snakemake --cores 100 --use-conda --printshellcmds --rerun-incomplete --keep-going --rerun-triggers mtime --until md5sum
# Run on everything:
#  snakemake --cores 100 --use-conda --printshellcmds --rerun-incomplete --keep-going --rerun-triggers mtime --config

# NOTE: If you need, you can specify a temp directory, e.g. with:
# snakemake --cores 100 --use-conda --printshellcmds --rerun-incomplete --rerun-triggers mtime --keep-going --default-resources "tmpdir='/scratch-raid0/tmp/'"
