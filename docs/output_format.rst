Output Format Reference
=======================

Everything is written under ``data/``, by experiment and then by sample.

Directory Structure
-------------------

.. code-block::

   data/
   ├── reference/                         # Masked GRCh38 and indices (built once, shared)
   ├── EXPERIMENT.csv                     # Your sample definitions
   ├── EXPERIMENT/
   │   ├── SAMPLE_01/
   │   │   ├── SAMPLE_01.bam              # Sorted, duplicate-marked alignment (write-protected)
   │   │   ├── SAMPLE_01.bam.bai          # BAM index
   │   │   ├── bam2tensor/                # Read-level methylation tensors (optional)
   │   │   ├── beds/                      # CpG methylation calls
   │   │   ├── biscuit/                   # biscuit QC
   │   │   ├── epibeds/                   # Read-level methylation (optional)
   │   │   ├── fastp/                     # Trimming statistics
   │   │   ├── fastqc/                    # FastQC report
   │   │   ├── goleft/                    # Coverage plots
   │   │   ├── logs/                      # Logs and benchmarks from each step
   │   │   ├── methyldackel/              # M-bias plots
   │   │   ├── raw/                       # Your raw reads, plus md5 checksums and validation
   │   │   ├── samtools/                  # Alignment statistics
   │   │   ├── wgbs_tools/                # pat/beta files
   │   │   └── .pipeline-complete-v2      # Marks the sample as finished
   │   ├── SAMPLE_02/
   │   │   └── ...
   │   └── multiqc/                       # Experiment-level MultiQC report
   └── EXPERIMENT_subsampled/             # Same layout, for subsampled runs
       └── ...

Alignment
---------

- ``SAMPLE.bam``: coordinate-sorted, with duplicates marked (not removed). Reads that look non-converted carry
  the ``XX:Z:UC`` tag and the QC-fail flag (0x200).
- ``SAMPLE.bam.bai``: its index

Methylation Calls
-----------------

**Bed** (``beds/SAMPLE.bed.gz`` and ``.tbi``)

The output of ``biscuit pileup | biscuit vcf2bed -k 3 -t cg | biscuit mergecg``: one line per CpG
**dinucleotide** (both strands merged), for CpGs covered by at least 3 reads.

1. **Chromosome**
2. **Start**: 0-based start of the CpG
3. **End**: start + 2
4. **Beta**: methylation fraction (0.0-1.0)
5. **Coverage**: number of reads covering the CpG

See the `biscuit methylation extraction docs <https://huishenlab.github.io/biscuit/docs/methylextraction.html>`_
for the authoritative description.

**wgbs_tools** (``wgbs_tools/``)

- ``SAMPLE.pat.gz`` (and ``.csi``): read-level CpG methylation patterns (chromosome, CpG index, pattern, count)
- ``SAMPLE.beta``: a binary array of (methylated, total) read counts per CpG; not a text file
- ``SAMPLE.mbias/``: per-strand M-bias tables

See the `wgbs_tools format docs <https://github.com/nloyfer/wgbs_tools/blob/master/docs/pat_format.md>`_.

**bam2tensor** (``bam2tensor/SAMPLE.methylation.npz``, only with ``--config bam2tensor=True``)

A NumPy ``.npz`` archive holding a sparse matrix with one row per read (mates merged into one fragment) and one
column per CpG, plus metadata. See the `bam2tensor docs <https://github.com/mcwdsi/bam2tensor>`_ for the encoding and
for how to load it; ``bam2tensor-inspect`` summarizes a file.

**Epibed** (``epibeds/SAMPLE.epibed.gz`` and ``.tbi``, not built by default)

The bgzipped, tabix-indexed output of ``biscuit epiread``: one line per read, with run-length-encoded
methylation states. See the `biscuit epiBED docs <https://huishenlab.github.io/biscuit/docs/epiread>`_.

Quality Control
---------------

.. list-table::
   :header-rows: 1
   :widths: 40 60

   * - File
     - Contents
   * - ``fastp/SAMPLE.fastp.json``, ``.html``
     - Read counts before and after filtering, adapter content, quality and length distributions
   * - ``fastp/failed.fa.gz``
     - Reads dropped by fastp
   * - ``fastqc/SAMPLE_fastqc.html``
     - FastQC report on the final ``.bam``
   * - ``samtools/SAMPLE.flagstat.txt``
     - Alignment summary
   * - ``samtools/SAMPLE.idxstats.txt``
     - Reads per chromosome
   * - ``samtools/SAMPLE.stats.txt``
     - Detailed alignment metrics
   * - ``samtools/SAMPLE.markdup.txt``
     - Duplicate statistics
   * - ``biscuit/``
     - biscuit QC tables: conversion, coverage, insert sizes, mapping quality
   * - ``methyldackel/mbias.txt``, ``mbias_OT.svg``, ``mbias_OB.svg``
     - M-bias by read position, for the original top and bottom strands
   * - ``goleft/index.html``
     - Interactive coverage plots
   * - ``EXPERIMENT/multiqc/multiqc_report.html``
     - All of the above, across the experiment's samples

Logs
----

Each step logs to ``logs/`` in the sample directory, for example ``fastp.log.txt``, ``bwameth.log.txt``,
``mark-nonconverted.log.txt``, ``samtools-*.log.txt``, ``biscuit-*.log.txt`` and ``bam2tensor.log.txt``.
Runtime and memory benchmarks for alignment, sorting and subsampling are in ``logs/benchmark/``.
MultiQC logs to ``EXPERIMENT/multiqc/log.txt``.

Reference Files
---------------

Built once in ``data/reference/`` and shared by all experiments:

- ``GRCh38.fna``: the unmasked download
- ``GRCh38-DAC-U2AF1.fna``: the masked reference that everything aligns to
- ``GRCh38-DAC-U2AF1.fna.bwameth.c2t*``: bwameth (bwa-mem2) indices
- ``GRCh38-DAC-U2AF1.fna.bis.*``, ``.dau.*``, ``.par.*``: biscuit indices
- ``biscuit_qc/``: biscuit QC assets
- ``bam2tensor/``: bam2tensor's CpG position cache (only with ``--config bam2tensor=True``)
- The two exclusion ``.bed`` files, and an intermediate ``GRCh38-DAC.fna``

Working With the Output
-----------------------

.. code-block:: bash

   # Methylation calls in a region
   tabix SAMPLE.bed.gz chr1:1000000-2000000

   # Methylation calls that overlap a set of features
   bedtools intersect -a SAMPLE.bed.gz -b features.bed

   # Summarize a bam2tensor file
   bam2tensor-inspect SAMPLE.methylation.npz

See :doc:`pipeline_details` for how each of these outputs is made.
