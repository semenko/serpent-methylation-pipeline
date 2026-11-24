# Pipeline Details

How each step works, and why. The Snakefile is the source of truth, and its comments record more of the reasoning.

## Overview

1. **Reference**: download GRCh38, mask it, and build indices (once)
2. **Checksums**: verify the MD5 of the raw reads
3. **Trimming**: fastp
4. **Alignment**: bwameth on bwa-mem2
5. **Post-processing**: mark non-converted reads, fix mates, sort, mark duplicates
6. **Methylation calling**: biscuit bed files and wgbs_tools pat/beta files
7. **QC**: per-sample tools, then MultiQC per experiment
8. **Optional**: bam2tensor tensors and biscuit epibeds

Steps 3 to 5 run as one job group (`align_core`) connected by named pipes:
fastp → bwameth → mark-nonconverted → samtools. No intermediate `.fastq` or `.sam` file is written to disk.

## Reference Genome

I chose the NCBI GRCh38 `no_alt_plus_hs38d1` analysis set:

- No patches
- Includes the hs38d1 decoy
- No ALT contigs

Two sets of regions are then masked (replaced with N), giving `data/reference/GRCh38-DAC-U2AF1.fna`:

- The [U2AF1 exclusions](https://genomeref.blogspot.com/2021/07/one-of-these-things-doest-belong.html)
  (`GCA_000001405.15_GRCh38_GRC_exclusions.bed` from NCBI)
- The [ENCODE DAC exclusion list](https://www.encodeproject.org/annotations/ENCSR636HFF/) (`ENCFF356LFX`)

NCBI explains the analysis sets in
[this README](https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/001/405/GCA_000001405.15_GRCh38/seqs_for_alignment_pipelines.ucsc_ids/README_analysis_sets.txt).

## Checksums

The `md5sum` rule compares each read file with the checksum in the experiment CSV, and nothing else runs for a
sample until it passes. It uses `md5sum`, or `md5` on systems without it (macOS).

## Trimming

I chose a relatively conservative approach to trimming, which is needed because of end-repair bias, adaptase bias and more.

| Method | R1 5' | R1 3' | R2 5' | R2 3' |
| ------ | ----- | ----- | ----- | ----- |
| EM-seq | 10 bp | 10 bp | 10 bp | 10 bp |
| BS-seq | 10 bp | 10 bp | 15 bp | 10 bp |

- **EM-seq**: 10 bp everywhere, after my own QC and offline discussions with NEB
  ([notes](https://github.com/FelixKrueger/Bismark/issues/509))
- **BS-seq**: an extra 5 bp from the 5' end of R2, because of adaptase bias
- **Adapters**: TruSeq sequences are given explicitly (no auto-detection)
- **Poly-G**: not forced; fastp trims poly-G tails when it detects two-color (NextSeq/NovaSeq) data
- **Length**: reads shorter than 15 bp after trimming are dropped

Quality filtering is minimal: fastp's **default** filter only (reads with more than 40% of bases below Q15, or
more than 5 Ns, are dropped). I experimented with stricter filtering early on and found little benefit, so filter on MAPQ or base quality
downstream as needed. Dropped reads are written to `fastp/failed.fa.gz`.

## Alignment

[bwameth](https://github.com/brentp/bwa-meth) aligns with the [bwa-mem2](https://github.com/bwa-mem/bwa-mem2)
backend, which is much faster than classic `bwa mem`. Each read gets a read group whose ID and sample name
are the `sample_id`. bwameth uses every core the rest of the job group does not need (all but 8 on a large machine).

Alignment originally used biscuit, which writes very well annotated `.bam` files and supports SNV calling, but
takes roughly 30 hours per sample on a 40-core machine. That rule is kept, commented out, in the Snakefile.

## Post-Alignment Processing

**Non-conversion marking.** [mark-nonconverted-reads](https://github.com/nebiolabs/mark-nonconverted-reads)
flags reads with 3 or more non-converted Cs. It sets the `XX:Z:UC` tag and the QC-fail flag
(0x200). Flagged reads stay in the `.bam`; tools that skip QC-failed reads ignore them.

**Duplicate marking.** `samtools fixmate` (adds mate tags) → `samtools sort` → `samtools markdup`.
Duplicates are marked, not removed. The `.bam` is written with level-1 compression, for speed, and is
write-protected.

## Methylation Calling

**biscuit bed.** `biscuit pileup` → `biscuit vcf2bed -k 3 -t cg` → `biscuit mergecg` → `bgzip` and
`tabix`. The result has one line per CpG dinucleotide, with both strands merged, for CpGs covered by at least
3 reads.

**wgbs_tools.** `wgbstools bam2pat` writes pat and beta files and M-bias tables.

**Epibeds (not run by default).** The `biscuit_epiread` rule writes read-level epibeds, but nothing depends on
it. Ask for `workflow/../data/EXPERIMENT/SAMPLE/epibeds/SAMPLE.epibed.gz` as a target, or add it to
`touch_complete_flag`.

**bam2tensor (optional).** With `--config bam2tensor=True`, [bam2tensor](https://github.com/mcwdsi/bam2tensor)
writes a sparse read-by-CpG matrix per sample. It runs with its defaults: chr1-22, X and Y; MAPQ of at least 20
and base quality of at least 20; proper pairs only; duplicates and QC-failed reads (so also reads flagged as
non-converted) are skipped. The first run caches the reference's CpG positions in
`data/reference/bam2tensor/`, which takes about 10 minutes. This step is not part of a sample's completion
flag, so it can be added to finished runs.

## Quality Control

Per sample:

- **fastp**: trimming and filtering statistics
- **FastQC**: run on the final `.bam`
- **samtools**: `flagstat`, `idxstats`, `stats` and duplicate statistics
- **biscuit QC**: bisulfite-specific metrics (conversion, coverage, insert sizes)
- **MethylDackel**: M-bias plots, to check the trimming
- **goleft indexcov**: coverage estimated from the `.bam` index

Per experiment, **MultiQC** gathers these into one report once all of the experiment's samples have finished.

## Software

Everything is installed from `workflow/envs/env.yaml` (which holds the minimum versions), except:

- **wgbs_tools**: not on conda; installed by hand (see [Installation](installation.md)). Note that its license is restrictive.
- **bam2tensor**: optional; `pip install bam2tensor`

## Background & Inspiration

I strongly suggest reading work from Felix Krueger (author of Bismark) as background. In particular:

- TrimGalore's [RRBS guide](https://github.com/FelixKrueger/TrimGalore/blob/master/Docs/RRBS_Guide.pdf)
- The Babraham [WGBS/RRBS tutorials](https://www.bioinformatics.babraham.ac.uk/training.html#bsseq)

For similar pipelines, see:

- NEB's [EM-seq pipeline](https://github.com/nebiolabs/EM-seq/)
- Felix Krueger's [Nextflow WGBS pipeline](https://github.com/FelixKrueger/nextflow_pipelines/blob/master/nf_bisulfite_WGBS)
- The Snakepipes [WGBS pipeline](https://snakepipes.readthedocs.io/en/latest/content/workflows/WGBS.html)
