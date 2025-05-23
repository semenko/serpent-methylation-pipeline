Configuration
=============

Data Organization
-----------------

The pipeline expects data to be organized in the ``data/`` directory with CSV files defining experiments.

Sample Definition Files
-----------------------

Create CSV files in ``data/`` directory (e.g., ``data/experiment1.csv``, ``data/test.csv``).

**Required Columns:**

.. list-table::
   :header-rows: 1
   :widths: 20 20 60

   * - Column
     - Type
     - Description
   * - ``sample_id``
     - string
     - Unique identifier for the sample
   * - ``path_R1``
     - string
     - Path to R1 FASTQ file (relative to sample directory)
   * - ``path_R2``
     - string
     - Path to R2 FASTQ file (relative to sample directory)
   * - ``method``
     - string
     - Sequencing method: "emseq" or "bs-seq"
   * - ``md5sum_R1``
     - string
     - MD5 checksum for R1 file validation
   * - ``md5sum_R2``
     - string
     - MD5 checksum for R2 file validation

**Optional Columns:**

.. list-table::
   :header-rows: 1
   :widths: 20 60

   * - Column
     - Description
   * - ``source``
     - Sample source (e.g., "plasma", "tissue")
   * - ``cell_type``
     - Cell type description
   * - ``description``
     - Additional sample description
   * - ``batch``
     - Sequencing batch information
   * - ``target_depth``
     - Expected sequencing depth

Example Configuration
---------------------

**data/experiment1.csv:**

.. code-block:: csv

   sample_id,source,cell_type,method,description,path_R1,path_R2,md5sum_R1,md5sum_R2
   Sample_001,plasma,cfdna,emseq,Test sample,sample1_R1.fastq.gz,sample1_R2.fastq.gz,abc123...,def456...
   Sample_002,tissue,bulk,bs-seq,Control sample,sample2_R1.fastq.gz,sample2_R2.fastq.gz,ghi789...,jkl012...

Directory Structure
-------------------

Expected data organization:

.. code-block::

   data/
   ├── experiment1.csv              # Sample definitions
   ├── test.csv                     # Test dataset
   ├── experiment1/                 # Experiment directory
   │   ├── Sample_001/
   │   │   └── raw/
   │   │       ├── sample1_R1.fastq.gz
   │   │       └── sample1_R2.fastq.gz
   │   └── Sample_002/
   │       └── raw/
   │           ├── sample2_R1.fastq.gz
   │           └── sample2_R2.fastq.gz

Pipeline Configuration
----------------------

**Snakefile Configuration**

Key parameters can be modified in ``workflow/Snakefile``:

.. code-block:: python

   # Filter to EM-seq only samples
   EMSEQ_ONLY = False  # Set to True to process only EM-seq data
   
   # Subsampling parameters (in seqtk_subsample rule)
   reads = 5000000  # Number of reads per pair for subsampling

**Method-Specific Trimming**

The pipeline automatically adjusts trimming based on the ``method`` column:

- **EM-seq**: 10bp trimmed from all ends
- **BS-seq**: 15bp trimmed from R2 5' end, 10bp from other ends

Reference Genome Configuration
------------------------------

The pipeline uses GRCh38 with specific modifications:

- **Base**: GRCh38 (no patches)
- **Includes**: hs38d1 decoy sequences
- **Masking**: U2AF1 and ENCODE DAC exclusion regions
- **Format**: No ALT chromosomes in main analysis

Environment Configuration
-------------------------

**Conda Environment** (``workflow/envs/env.yaml``):

Key dependencies are automatically managed:

- biscuit (≥1.2.1)
- bwameth (≥0.2.7)
- samtools (≥1.17)
- fastp (≥0.23.2)
- multiqc (≥1.14)

Advanced Configuration
----------------------

**Resource Limits**

Modify resource requirements in individual rules:

.. code-block:: python

   # Example: Increase memory for alignment
   resources:
      mem_mb = 128000  # 128GB RAM

**Custom Parameters**

Key parameters can be customized:

.. code-block:: python

   # fastp trimming (in fastp rule)
   minimum_length = 15
   
   # biscuit bed generation (in biscuit_bed rule)  
   minimum_reads = 3

Validation
----------

**Test Configuration**

Use the provided test dataset:

.. code-block:: bash

   # Test with provided test.csv
   snakemake --cores 4 --use-conda --dry-run

**Sample Validation**

The pipeline validates:

- Required columns are present
- MD5 checksums match input files
- File paths are accessible

Troubleshooting Configuration
-----------------------------

**Common Issues:**

1. **Missing files**: Ensure FASTQ paths are correct relative to sample directories
2. **MD5 mismatches**: Verify file integrity and checksums
3. **Method specification**: Use exactly "emseq" or "bs-seq" (case-sensitive)

Next Steps
----------

After configuration, proceed to :doc:`usage` to run the pipeline.
