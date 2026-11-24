# Serpent Methylation Pipeline

```{image} ../serpent-logo.png
:align: center
:alt: Serpent Pipeline Logo
:width: 400px
```

A standardized, reproducible Snakemake pipeline for WGBS bisulfite and EM-seq data. It goes from `.fastq.gz`
to methylation calls, aligning with bwameth (on bwa-mem2) and calling with biscuit, with extensive QC along the way.

```{toctree}
:hidden:
:maxdepth: 2

installation
configuration
usage
pipeline_details
output_format
```

## Quick Start

```bash
git clone https://github.com/semenko/serpent-methylation-pipeline.git
cd serpent-methylation-pipeline
mamba install -c conda-forge -c bioconda snakemake snakemake-storage-plugin-http

# Show the execution plan for the bundled test sample
snakemake --cores 4 --use-conda --dry-run
```

A real run needs Linux, a large machine and a manual `wgbs_tools` install: see [Installation](installation.md).

## Features

- **One file**: the whole pipeline is `workflow/Snakefile`, with the reasoning behind each choice in comments
- **Fast alignment**: bwameth on the bwa-mem2 backend, streamed through pipes to sorted, duplicate-marked `.bam`
- **Non-conversion detection**: reads that look unconverted are flagged
- **Methylation calls**: biscuit bed files and wgbs_tools pat/beta files
- **QC**: fastp, FastQC, samtools, biscuit QC, MethylDackel M-bias and goleft, gathered by MultiQC
- **Subsampling**: an optional quick pass over 5M read pairs per sample
- **Optional exports**: read-level tensors with bam2tensor, and biscuit epibeds

## Citing

If you use this pipeline, please cite it using the metadata in
[CITATION.cff](https://github.com/semenko/serpent-methylation-pipeline/blob/main/CITATION.cff)
(GitHub shows a "Cite this repository" button), and name the release you ran.
