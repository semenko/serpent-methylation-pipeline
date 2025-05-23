Pipeline Technical Details
==========================

This document provides detailed technical information about the Serpent Methylation Pipeline implementation.

Pipeline Overview
-----------------

The pipeline processes WGBS bisulfite and EM-seq data through several key stages:

1. **Reference Preparation**: Downloads and masks GRCh38 reference
2. **Quality Control & Trimming**: Uses fastp for adapter trimming and quality filtering
3. **Alignment**: Uses bwameth with bwa-mem2 for bisulfite-aware alignment
4. **Post-processing**: Marks duplicates and non-converted reads
5. **Methylation Calling**: Uses biscuit for methylation extraction
6. **Quality Assessment**: Comprehensive QC across multiple tools
7. **Output Generation**: Creates standardized bed, pat/beta, and epibed formats

Reference Genome Details
------------------------

**GRCh38 Configuration:**

- **Base**: GRCh38 (no patches)
- **Decoy**: Includes hs38d1 decoy sequences
- **Exclusions**: 
  - U2AF1 masking regions
  - ENCODE DAC exclusion list
- **Format**: No ALT chromosomes in main analysis

The reference is downloaded from NCBI and processed to apply masking files:

.. code-block:: bash

   # U2AF1 masking
   https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/405/GCF_000001405.40_GRCh38.p14/GRCh38_major_release_seqs_for_alignment_pipelines/GCA_000001405.15_GRCh38_GRC_exclusions.bed
   
   # ENCODE DAC exclusion
   https://encode-public.s3.amazonaws.com/2020/05/05/bc5dcc02-eafb-4471-aba0-4ebc7ee8c3e6/ENCFF356LFX.bed.gz

Alignment Strategy
------------------

**Primary Aligner: bwameth + bwa-mem2**

The pipeline uses `bwameth <https://github.com/brentp/bwa-meth>`_ with the `bwa-mem2 <https://github.com/bwa-mem/bwa-mem2>`_ backend:

- **Speed**: bwa-mem2 provides 2-3x speedup over standard bwa
- **Accuracy**: Maintains bwameth's bisulfite-aware alignment
- **Memory**: Optimized memory usage for large genomes
- **Threading**: Scales well with available CPU cores

**Alignment Parameters:**

- Uses interleaved FASTQ input from fastp
- Applies read group information for sample tracking
- Outputs uncompressed SAM for downstream processing

**Alternative: biscuit (currently disabled)**

The pipeline includes biscuit alignment support but it's currently disabled due to performance:

- **Accuracy**: Excellent for SNV calling
- **Speed**: ~30 hours per sample on 40-core machine
- **Use case**: Enable for projects requiring SNV analysis

Trimming Strategy
-----------------

**Method-Specific Trimming:**

+----------+----------+----------+----------+----------+
| Method   | R1 5'    | R1 3'    | R2 5'    | R2 3'    |
+==========+==========+==========+==========+==========+
| EM-seq   | 10 bp    | 10 bp    | 10 bp    | 10 bp    |
+----------+----------+----------+----------+----------+
| BS-seq   | 10 bp    | 10 bp    | 15 bp    | 10 bp    |
+----------+----------+----------+----------+----------+

**Trimming Rationale:**

- **EM-seq**: Conservative 10bp trimming based on NEB recommendations
- **BS-seq**: Additional 5bp R2 5' trimming due to adaptase bias
- **Poly-G**: Removes poly-G sequences from two-color chemistry
- **Length**: Minimum 15bp read length requirement

**Quality Filtering:**

Quality filtering is intentionally **disabled** (``--disable_quality_filtering``) to preserve data for downstream analysis-specific filtering.

Post-Alignment Processing
-------------------------

**Non-Conversion Marking:**

Uses `mark-nonconverted-reads <https://github.com/nebiolabs/mark-nonconverted-reads>`_:

- **Threshold**: 3+ non-converted cytosines per read
- **Marking**: Sets XX:Z:UC tag and vendor failed bit
- **Purpose**: Identifies incomplete bisulfite conversion

**Duplicate Marking:**

Standard samtools workflow:

1. **fixmate**: Adds mate score and MC tags
2. **sort**: Coordinate-sorted output
3. **markdup**: Marks PCR duplicates with statistics

Methylation Calling
-------------------

**biscuit pileup → bed Pipeline:**

.. code-block:: bash

   biscuit pileup → biscuit vcf2bed → biscuit mergecg → bgzip + tabix

**Parameters:**

- **Minimum reads**: 3 reads per CpG site
- **Coverage**: Retains sites with ≥3x coverage
- **Format**: Compressed bed with tabix index
- **Merge**: CpG sites are merged for analysis

**Output Formats:**

1. **Bed files**: Standard methylation calls
2. **Epibeds**: Read-level methylation patterns
3. **Pat/Beta**: wgbs_tools format for downstream analysis

Quality Control Components
--------------------------

**Per-Sample QC:**

- **FastQC**: Read quality assessment on final BAM
- **fastp**: Trimming and filtering statistics
- **samtools stats**: Alignment statistics and insert sizes
- **MethylDackel**: M-bias plots for trimming validation
- **biscuit QC**: Comprehensive bisulfite-specific metrics
- **goleft indexcov**: Coverage visualization

**Project-Level QC:**

- **MultiQC**: Aggregated report across all samples
- **Cross-sample comparison**: Batch effect detection
- **Summary statistics**: Project-wide metrics

Performance Considerations
--------------------------

**Resource Requirements:**

- **Memory**: 64-128GB recommended for alignment
- **CPU**: Scales linearly with core count
- **Storage**: ~100GB per sample for intermediate files
- **Network**: Initial download of reference genomes

**Optimization Features:**

- **Subsampling**: 5M read pairs for rapid QC
- **Temporary files**: Automatic cleanup of intermediate files
- **Parallel processing**: Group-based rule execution
- **Compression**: Level-1 BAM compression for speed

**Cluster Compatibility:**

The pipeline includes safeguards for cluster execution:

- **Thread limiting**: Prevents over-allocation
- **Memory management**: Configurable per-rule limits
- **Temporary directories**: Configurable scratch space

Output File Organization
------------------------

**Directory Structure:**

.. code-block::

   EXPERIMENT/
   ├── SAMPLE/
   │   ├── SAMPLE.bam              # Final alignment
   │   ├── SAMPLE.bam.bai          # BAM index
   │   ├── beds/                   # Methylation bed files
   │   ├── epibeds/                # Read-level methylation
   │   ├── wgbs_tools/             # Pat/beta format files
   │   ├── biscuit/                # Biscuit QC files
   │   ├── fastp/                  # Trimming statistics
   │   ├── fastqc/                 # Quality control
   │   ├── goleft/                 # Coverage plots
   │   ├── methyldackel/           # M-bias plots
   │   ├── samtools/               # Alignment statistics
   │   └── logs/                   # Process logs
   └── multiqc/                    # Project summary

Software Dependencies
---------------------

**Core Tools:**

- **bwameth** (≥0.2.7): Bisulfite alignment
- **bwa-mem2** (≥2.2.1): Fast alignment backend  
- **biscuit** (≥1.2.1): Methylation calling
- **fastp** (≥0.23.2): Read processing
- **samtools** (≥1.17): BAM manipulation

**QC Tools:**

- **FastQC** (≥0.12.1): Read quality
- **MultiQC** (≥1.14): Report aggregation
- **MethylDackel** (≥0.6.1): M-bias analysis
- **goleft** (≥0.2.4): Coverage analysis

**Utilities:**

- **mark-nonconverted-reads** (≥1.2): Non-conversion detection
- **seqtk** (≥1.3): Read subsampling
- **bedtools**: Genome interval operations
- **wgbs_tools**: Pat/beta format generation

All dependencies are managed through conda environments for reproducibility.
