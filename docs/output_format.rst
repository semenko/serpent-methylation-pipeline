Output Format Reference
=======================

The Serpent Methylation Pipeline generates comprehensive outputs organized by experiment and sample. This document describes all output files and their formats.

Directory Structure
-------------------

**Standard Analysis:**

.. code-block::

   data/
   ├── EXPERIMENT/
   │   ├── SAMPLE_01/
   │   │   ├── SAMPLE_01.bam              # Final alignment file
   │   │   ├── SAMPLE_01.bam.bai          # BAM index
   │   │   ├── beds/                      # Methylation calls
   │   │   ├── epibeds/                   # Read-level methylation
   │   │   ├── wgbs_tools/                # Pat/beta format files
   │   │   ├── biscuit/                   # Biscuit QC output
   │   │   ├── fastp/                     # Trimming statistics
   │   │   ├── fastqc/                    # Quality control
   │   │   ├── goleft/                    # Coverage analysis
   │   │   ├── methyldackel/              # M-bias plots
   │   │   ├── samtools/                  # Alignment statistics
   │   │   ├── raw/                       # Input FASTQ files
   │   │   └── logs/                      # Process logs
   │   ├── SAMPLE_02/
   │   │   └── ...
   │   └── multiqc/                       # Project-wide QC
   └── EXPERIMENT_subsampled/             # Subsampled analysis
       └── ...

Core Output Files
-----------------

**Primary Alignment:**

- ``SAMPLE.bam``: Final coordinate-sorted BAM file with duplicates marked
- ``SAMPLE.bam.bai``: BAM index for rapid access

**Methylation Data:**

- ``beds/SAMPLE.bed.gz``: Compressed methylation calls (CpG sites)
- ``beds/SAMPLE.bed.gz.tbi``: Tabix index for bed file
- ``epibeds/SAMPLE.epibed.gz``: Read-level methylation patterns
- ``epibeds/SAMPLE.epibed.gz.tbi``: Tabix index for epibed

File Format Specifications
--------------------------

**Methylation Bed Format**

The main methylation output follows a 6-column bed format:

.. code-block::

   chr1    3000827    3000828    CG:4    1.000    +
   chr1    3001007    3001008    CG:8    0.875    +
   chr1    3001018    3001019    CG:5    0.800    -

**Columns:**

1. **Chromosome**: Reference sequence name
2. **Start**: 0-based start position
3. **End**: 1-based end position (start + 1)
4. **Name**: ``CG:coverage`` (number of reads covering site)
5. **Score**: Methylation beta value (0.0-1.0)
6. **Strand**: ``+`` or ``-``

**Epibed Format**

Read-level methylation patterns from biscuit epiread:

.. code-block::

   chr1    3000827    3000850    read1    23    +    C.C
   chr1    3001007    3001025    read2    18    -    c.C

**Columns:**

1. **Chromosome**: Reference sequence name
2. **Start**: Start position of methylation pattern
3. **End**: End position of methylation pattern  
4. **Read ID**: Unique read identifier
5. **Mapping Quality**: MAPQ score
6. **Strand**: Read strand
7. **Pattern**: Methylation pattern (C=methylated, c=unmethylated, .=reference C)

**wgbs_tools Formats**

**Pat Files** (``wgbs_tools/SAMPLE.pat.gz``):

Compressed, indexed methylation patterns:

.. code-block::

   chr1    3000827    C.C.CC    5
   chr1    3001007    c.C       3

**Beta Files** (``wgbs_tools/SAMPLE.beta``):

Beta values for genomic regions:

.. code-block::

   chr1:3000827    0.800    5
   chr1:3001007    0.667    3

Quality Control Outputs
-----------------------

**fastp Statistics** (``fastp/SAMPLE.fastp.json``):

- Read counts before/after filtering
- Adapter contamination rates
- Quality score distributions
- Length distributions

**FastQC Reports** (``fastqc/SAMPLE_fastqc.html``):

- Per-base sequence quality
- Per-sequence quality scores
- Sequence length distribution
- Overrepresented sequences

**samtools Statistics** (``samtools/``):

- ``SAMPLE.flagstat.txt``: Alignment summary statistics
- ``SAMPLE.idxstats.txt``: Reads per chromosome
- ``SAMPLE.stats.txt``: Detailed alignment metrics
- ``SAMPLE.markdup.txt``: PCR duplicate statistics

**biscuit QC** (``biscuit/``):

- Conversion rate analysis
- Strand bias assessment
- Insert size distributions
- Mapping quality distributions
- CpG coverage statistics

**MethylDackel M-bias** (``methyldackel/``):

- ``mbias.txt``: M-bias statistics by position
- ``mbias_OT.svg``: Original top strand M-bias plot
- ``mbias_OB.svg``: Original bottom strand M-bias plot

**goleft Coverage** (``goleft/index.html``):

- Interactive coverage visualization
- Depth distribution across chromosomes
- Coverage uniformity assessment

Log Files
---------

**Process Logs** (``logs/``):

Each processing step generates detailed logs:

- ``fastp.log.txt``: Read trimming and filtering
- ``bwameth.log.txt``: Alignment process
- ``mark-nonconverted.log.txt``: Non-conversion detection
- ``samtools-*.log.txt``: BAM processing steps
- ``biscuit-*.log.txt``: Methylation calling
- ``multiqc/log.txt``: QC aggregation

**Benchmark Files** (``logs/benchmark/``):

Runtime and resource usage for key steps:

- ``bwameth.txt``: Alignment performance
- ``samtools.txt``: BAM processing performance
- ``seqtk_subsampling.txt``: Subsampling performance

Project-Level Outputs
----------------------

**MultiQC Report** (``multiqc/multiqc_report.html``):

Comprehensive project summary including:

- Sample quality overview
- Alignment statistics across samples
- Conversion efficiency comparison
- Batch effect detection
- Interactive plots and tables

**Reference Files** (``reference/``):

Generated once per pipeline run:

- ``GRCh38-DAC-U2AF1.fna``: Masked reference genome
- ``GRCh38-DAC-U2AF1.fna.bis.*``: biscuit indices
- ``GRCh38-DAC-U2AF1.fna.bwameth.*``: bwameth indices
- ``biscuit_qc/``: QC reference assets

Subsampled Data Outputs
------------------------

Subsampled analyses (``EXPERIMENT_subsampled/``) generate identical file structures with reduced data:

- **Purpose**: Rapid QC and preliminary analysis
- **Size**: 5M read pairs per sample (10M total reads)
- **Structure**: Identical to full analysis
- **Use case**: Quick validation before full processing

File Size Expectations
----------------------

**Per Sample (typical 30x coverage):**

- Raw FASTQ: 50-100 GB
- Final BAM: 15-25 GB  
- Methylation bed: 200-500 MB
- Epibed: 1-3 GB
- wgbs_tools files: 100-300 MB
- QC outputs: 10-50 MB

**Storage Recommendations:**

- Temporary space: 2-3x raw FASTQ size
- Final storage: 1.5x raw FASTQ size
- Reference files: ~20 GB (shared across projects)

Data Access and Analysis
------------------------

**Recommended Tools:**

- **bedtools**: Intersect methylation with genomic features
- **tabix**: Random access to compressed bed files
- **samtools**: BAM file manipulation
- **wgbs_tools**: Downstream methylation analysis
- **R/Bioconductor**: Statistical analysis with packages like bsseq, methylKit

**Example Usage:**

.. code-block:: bash

   # Extract methylation for specific region
   tabix SAMPLE.bed.gz chr1:1000000-2000000
   
   # Get read-level patterns for region
   tabix SAMPLE.epibed.gz chr1:1000000-2000000
   
   # Intersect with genomic features
   bedtools intersect -a features.bed -b SAMPLE.bed.gz

Quality Metrics Interpretation
------------------------------

**Key QC Thresholds:**

- **Conversion efficiency**: >95% for EM-seq, >90% for BS-seq
- **Alignment rate**: >85% for human samples
- **Duplicate rate**: <30% for high-quality libraries
- **Mean coverage**: Project-dependent (typically 10-30x)
- **CpG coverage**: >1M CpGs with ≥3x coverage

Next Steps
----------

See :doc:`troubleshooting` for guidance on interpreting QC metrics and addressing common issues.
