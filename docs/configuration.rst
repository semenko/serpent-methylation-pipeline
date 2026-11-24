Configuration
=============

There is no configuration file. Samples are defined in
CSV files, run modes are chosen with ``--config`` flags, and analysis parameters are set in the Snakefile.

Defining Samples
----------------

Each CSV file in ``data/`` defines one experiment, named after the file, and **every** CSV in ``data/`` is run.
``data/melanoma.csv`` defines the experiment ``melanoma``, whose reads are expected in
``data/melanoma/SAMPLE_ID/raw/``:

.. code-block::

   data/
   ├── melanoma.csv
   └── melanoma/
       ├── Sample_001/
       │   └── raw/
       │       ├── sample1_R1.fastq.gz
       │       └── sample1_R2.fastq.gz
       └── Sample_002/
           └── raw/
               ├── sample2_R1.fastq.gz
               └── sample2_R2.fastq.gz

**Required columns:**

.. list-table::
   :header-rows: 1
   :widths: 20 80

   * - Column
     - Description
   * - ``sample_id``
     - Sample name, also used as the directory name. Must be unique across *all* experiment files.
   * - ``path_R1``, ``path_R2``
     - Filenames of the paired ``.fastq.gz`` reads inside the sample's ``raw/`` directory
   * - ``method``
     - ``emseq`` or ``bsseq`` (case, hyphens and underscores are ignored, so ``EM-seq`` works). Controls trimming.
   * - ``md5sum_R1``, ``md5sum_R2``
     - Known MD5 checksums of the reads, verified before anything else runs

Any other columns are free-form metadata that the pipeline ignores. The bundled ``data/test.csv`` is a working
example with many such columns (``source``, ``cell_type``, ``batch`` and so on).

**What is checked:**

- A CSV that lacks a required column is an error.
- Rows missing a required value are skipped with a warning.
- A ``sample_id`` used twice, in any experiment, is an error.
- An unrecognized ``method`` gives a warning, and the sample is trimmed as EM-seq.
- A checksum mismatch fails that sample (``md5sum`` rule).

For backwards compatibility, a sample whose ``sample_id`` contains ``_bsseq`` is also trimmed as BS-seq.

Run Modes
---------

.. list-table::
   :header-rows: 1
   :widths: 35 65

   * - Flag
     - Effect
   * - ``--config make-subsampled=True``
     - Only write subsampled reads (5M read pairs per sample) to ``data/EXPERIMENT_subsampled/``
   * - ``--config analyze-subsampled=True``
     - Run the whole analysis on the subsampled reads only, generating them first if they are missing
   * - ``--config bam2tensor=True``
     - Also export read-level methylation tensors with bam2tensor
   * - ``--config ntfy_topic=TOPIC``
     - Send `ntfy.sh <https://ntfy.sh>`_ notifications to this topic

All are off by default. Boolean flags need a true value (``True``, ``1`` or ``yes``); ``make-subsampled=False``
is the same as leaving it out. Flags can be combined after a single ``--config``, except that ``make-subsampled``
and ``analyze-subsampled`` are mutually exclusive. See :doc:`usage` for examples.

Subsampled reads are always named ``R1.fastq.gz`` and ``R2.fastq.gz``, whatever ``path_R1`` and ``path_R2`` say,
and are not checksummed again.

Analysis Parameters
-------------------

These are set in ``workflow/Snakefile``. They were chosen from QC on real data, so change them deliberately.

.. list-table::
   :header-rows: 1
   :widths: 30 25 45

   * - Parameter
     - Where
     - Default
   * - ``EMSEQ_ONLY``
     - top of the file
     - ``False``. Set to ``True`` to skip BS-seq samples.
   * - Trimming lengths, minimum length, adapters
     - ``fastp`` rule
     - See :doc:`pipeline_details`
   * - ``threshold``
     - ``mark_nonconverted`` rule
     - 3 non-converted Cs flag a read
   * - ``minimum_reads``
     - ``biscuit_bed`` rule
     - 3 reads to report a CpG
   * - ``reads``, ``seed``
     - ``seqtk_subsample`` rule
     - 5,000,000 read pairs, seed 4242
   * - ``threads``, ``mem_mb``
     - each rule
     - Up to 128 GB (``biscuit_bed``)

The tool versions are set in ``workflow/envs/env.yaml``.

Next Steps
----------

Continue to :doc:`usage` to run the pipeline.
