# Snakemake Methylation Pipeline

[![Snakemake](https://img.shields.io/badge/snakemake-≥8.0.0-brightgreen.svg)](https://snakemake.github.io)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Code style: black](https://img.shields.io/badge/code%20style-black-000000.svg)](https://github.com/psf/black)


A standardized, reproducible pipeline to process WGBS bisulfite & EM-seq data. This goes from .fastq to methylation calls (via [biscuit](https://github.com/huishenlab/biscuit)) and includes extensive QC and plotting, using a Snakemake pipeline.

At a high level, this pipeline reproducibly:
- Builds a reference genome
- Trims & (minimally) filters reads
- Aligns & calls methylation using [biscuit](https://github.com/huishenlab/biscuit)
- Flags non-converted reads
- Generates standardized outputs & QC including
    - FastQC
    - fastp
    - Biscuit QC
    - samtools stats
    - MethylDackel mbias plots
    - Goleft covplots
    - epibed/epiread files
- Runs multiqc across entire projects

## Getting Started

This pipeline is designed to be straightforward:
1. Clone this repository and open the directory:
   ```
   git clone https://github.com/semenko/serpent-methylation-pipeline.git
   cd serpent-methylation-pipeline
   ```
2. Install mamba:
   ```
   conda install -c conda-forge mamba
   ```
   or install [mambaforge](https://github.com/conda-forge/miniforge#mambaforge).

3. Install Snakemake via mamba:
   ```
   mamba install -c bioconda -c conda-forge snakemake
   ```
4. (Optional) Create a separate conda environment for pipeline dependencies:
   ```
   mamba env create -n serpent_pipeline_env -f workflow/envs/env.yaml
   ```
   Then activate it with:
   ```
   conda activate serpent_pipeline_env
   ```

### Test Run
Use:
```
nice snakemake --cores 4 --use-conda --printshellcmds --rerun-incomplete --rerun-triggers mtime --keep-going --dry-run
```
to quickly validate the pipeline and see what would be executed. Remove `--dry-run` to run the full process.

After removing the `--dry-run` flag, this will download reference genomes and build indices.

### Data Definition


### Expected Output

Raw data files from [data](../data) are processed and analyzed by this snakemake workflow. Within each project directory, the output is (roughly) structured as:

    SAMPLE_01/                  # e.g. melanoma / crc / healthy, etc.
    │   SAMPLE.bam              # The final alignment file 
    |   SAMPLE.bam.bai          #   (and its index)
    |── biscuit_qc/             # biscuit QC.sh text files
    |── epibeds/                # epibed files (bgzip-compressed & tabix-indexed)
    ├── fastp/                  # fastp statistics & logs
    ├── fastqc/                 # fastqc graphs 
    ├── goleft/                 # goleft coverage plots
    ├── logs/                   # runlogs from each pipeline component
    ├── methyldackel/           # mbias plots
    ├── raw/
    │   ├── ...fastq.gz         # Raw reads
    |   ├── ...md5.txt          # Checksums and validation
    ├── samtools/               # samtools statistics
    SAMPLE_02/
    ...
    ...
    multiqc/                    # A project-level multiqc stats across all data

Note each project also has a `_subsampled` directory with identical structure, which is the result of the pipeline run on only 10M reads/sample.


### Production Runs


## Pipeline Details

This pipeline was designed for highly reproducible, explainable alignments and analysis of epigenetic sequencing data.

### Reference Genome

I chose **GRCh38**, with these specifics:
- No patches
- Includes the hs38d1 decoy
- Includes Alt chromosomes
- Applies the [U2AF1 masking file](https://genomeref.blogspot.com/2021/07/one-of-these-things-doest-belong.html)
- Applies the [Encode DAC exclusion](https://www.encodeproject.org/annotations/ENCSR636HFF/)

You can see a good explanation of the rationale for some of these components at [this NCBI explainer](https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/405/GCF_000001405.40_GRCh38.p14/GRCh38_major_release_seqs_for_alignment_pipelines/README_analysis_sets.txt).

### Requirements

All software requirements are specified in [env.yaml](workflow/envs/env.yaml).

Most are relatively common, but a few are semi-unique:
- [biscuit](https://github.com/huishenlab/biscuit) (for alignment)
- NEB's [mark-nonconverted-reads](https://github.com/nebiolabs/mark-nonconverted-reads) (to mark partially converted reads)

biscuit was chosen after a comparison with bwa-meth and bismark — its latest version was the most flexible with extremely well annotated .bams (some critical tags are missing from bwa-meth for identifying read level methylation, and would require patching MethylDackel to extract data).

I briefly experimented with [wgbs_tools](https://github.com/nloyfer/wgbs_tools) (which defines nice .pat/.beta formats) but its licensing is too restrictive to use.

### Trimming Approach

I chose a relatively conservative approach to trimming -- which is needed due to end-repair bias, adaptase bias, and more. 

For **EMseq**, I trim 10 bp everywhere, after personal QC and offline discussions with NEB. See [my notes here](https://github.com/FelixKrueger/Bismark/issues/509).

For **BSseq**, I trim 15 bp 5' R2, and 10 bp everywhere else due to adaptase bias.

For all reads, I set `--trim_poly_g` (due to [two color bias](https://sequencing.qcfail.com/articles/illumina-2-colour-chemistry-can-overcall-high-confidence-g-bases/)) and set a `--length_required` (minimum read length) of 10 bp.

### No Quality Filtering

Notably I do NOT do quality filtering here (I set `--disable_quality_filtering`), and save this for downstream analyses as desired.

I experimented with more stringent quality filtering early on, and found it had little yield / performance benefit. 


## Background & Inspiration

I strongly suggest reading work from Felix Krueger (author of Bismark) as background. In particular:
- TrimGalore's [RRBS guide](https://github.com/FelixKrueger/TrimGalore/blob/master/Docs/RRBS_Guide.pdf)
- The Babraham [WGBS/RRBS tutorials](https://www.bioinformatics.babraham.ac.uk/training.html#bsseq)

For similar pipelines and inspiration, see:
- NEB's [EM-seq pipeline](https://github.com/nebiolabs/EM-seq/)
- Felix Krueger's [Nextflow WGBS Pipeline](https://github.com/FelixKrueger/nextflow_pipelines/blob/master/nf_bisulfite_WGBS)
- The Snakepipes [WGBS pipeline](https://snakepipes.readthedocs.io/en/latest/content/workflows/WGBS.html)


## Pipeline Graph

Here's a high-level overview of the Snakemake pipeline (generated via `snakemake --rulegraph | dot -Tpng > rules.png`)

![image](https://user-images.githubusercontent.com/167135/211419041-54664bc2-3d5d-43ad-9dca-16d62da07d7b.png)

