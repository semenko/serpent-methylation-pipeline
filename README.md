# Snakemake Methylation Pipeline

A standardized, reproducible pipeline to process WGBS bisulfite & EM-seq data. This goes from .fastq to methylation calls (via [biscuit](https://github.com/huishenlab/biscuit)) and includes extensive QC and plotting, using a Snakemake pipeline.


## Reference Genome

I chose GRCh38, with these specifics:
- No patches
- Includes the hs38d1 decoy
- Includes Alt chromosomes
- Applies the [U2AF1 masking file](https://genomeref.blogspot.com/2021/07/one-of-these-things-doest-belong.html)
- Applies the [Encode DAC exclusion](https://www.encodeproject.org/annotations/ENCSR636HFF/)

You can see a good explanation of the rationale for some of these components at [this NCBI explainer](https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/405/GCF_000001405.40_GRCh38.p14/GRCh38_major_release_seqs_for_alignment_pipelines/README_analysis_sets.txt).

## Requirements

All software requirements are specified in `env.yaml` except for:
- biscuit itself, due to [this issue](https://github.com/huishenlab/biscuit/pull/31)

This uses a few ~unique packages, including
- NEB's [mark-nonconverted-reads.py package](https://github.com/nebiolabs/mark-nonconverted-reads)

Note, I previously experimented with [wgbs_tools](https://github.com/nloyfer/wgbs_tools), which defines nice .pat/.beta formats, but its licensing is too restrictive.

## Trimming Approach

For **EMseq**, I trim 10 bp everywhere.

For **BSseq**, I trim 15 BP of R2 5', and 10 bp everywhere else.

For all reads, I set `--trim_poly_g` (see [this note](https://sequencing.qcfail.com/articles/illumina-2-colour-chemistry-can-overcall-high-confidence-g-bases/)), and set a `--length_required` (minimum read length) of 15 bp.

Notably I do NOT do quality filtering here (I set `--disable_quality_filtering`), and save this for downstream analyses as desired. (In small-scale tests, early quality filtering doesn't seem to impact alignment results in any appreciable way.)

## Background & Inspiration

I strongly suggest reading work from Felix Krueger (author of Bismark) as background. In particular:
- TrimGalore's [RRBS guide](https://github.com/FelixKrueger/TrimGalore/blob/master/Docs/RRBS_Guide.pdf)
- The Babraham [WGBS/RRBS tutorials](https://www.bioinformatics.babraham.ac.uk/training.html#bsseq)

For similar pipelines and inspiration, see:
- NEB's [EM-seq pipeline](https://github.com/nebiolabs/EM-seq/)
- Felix Krueger's [Nextflow WGBS Pipeline](https://github.com/FelixKrueger/nextflow_pipelines/blob/master/nf_bisulfite_WGBS)
- The Snakepipes [WGBS pipeline](https://snakepipes.readthedocs.io/en/latest/content/workflows/WGBS.html)


## Pipeline Graph

Here's a high-level overview of the Snakemake pipeline, generated via `snakemake --rulegraph | dot -Tpng > rules.png`

<p align="center">
<img src="https://user-images.githubusercontent.com/167135/185484931-ccfa0549-6898-44e1-9be2-ee0cf25ee6b2.png" width="500">
</p>
