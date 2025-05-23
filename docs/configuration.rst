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
     - Sequencing method: "emseq" or "bs-seq" (case-sensitive)
   * - ``md5sum_R1``
     - string
     - MD5 checksum for R1 file validation
   * - ``md5sum_R2``
     - string
     - MD5 checksum for R2 file validation

**Optional Columns (from test.csv):**

.. list-table::
   :header-rows: 1
   :widths: 20 60

   * - Column
     - Description
   * - ``source``
     - Sample source (e.g., "plasma", "tissue")
   * - ``cell_type``
     - Cell type description (e.g., "cfdna", "bulk")
   * - ``description``
     - Additional sample description
   * - ``internal_path``
     - Internal tracking path
   * - ``batch``
     - Sequencing batch information
   * - ``batch_id``
     - Batch identifier
   * - ``sequencing_facility``
     - Facility where sequencing was performed
   * - ``target_depth``
     - Expected sequencing depth
   * - ``indexing_pcr_cycles``
     - Number of indexing PCR cycles
   * - ``ng_dna_for_prep``
     - DNA input amount for library prep
   * - ``ng_unmethylated_lambda``
     - Lambda DNA spike-in amount
   * - ``sorted_cells``
     - Number of sorted cells (if applicable)
   * - ``ng_sorted_dna``
     - DNA amount from sorted cells

Example Configuration
---------------------

**data/test.csv (actual format):**

.. code-block:: csv

   sample_id,source,cell_type,method,description,path_R1,path_R2,md5sum_R1,md5sum_R2,internal_path,batch,batch_id,sequencing_facility,target_depth,indexing_pcr_cycles,ng_dna_for_prep,ng_unmethylated_lambda,sorted_cells,ng_sorted_dna
   Test_SAMPLE1,plasma,cfdna,emseq,,1.fastq.gz,2.fastq.gz,62f0886509be1186c9b71f9f24e7ea27,a1cb70a3f16fe94e942c8d8f2fbeb8fd,,,,medgenome,,,,,,

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

- **emseq**: 10bp trimmed from all ends
- **bs-seq**: 15bp trimmed from R2 5' end, 10bp from other ends

**Pipeline Modes**

Configure pipeline behavior with config flags:

.. code-block:: bash

   # Generate subsampled data only
   snakemake --config make-subsampled=True
   
   # Analyze existing subsampled data
   snakemake --config analyze-subsampled=True

Reference Genome Configuration
------------------------------

The pipeline uses GRCh38 with specific modifications:

- **Base**: GRCh38 (no patches)
- **Includes**: hs38d1 decoy sequences  
- **Masking**: U2AF1 and ENCODE DAC exclusion regions
- **Format**: No ALT chromosomes in main analysis

The reference is automatically downloaded and processed on first run.

Environment Configuration
-------------------------

**Conda Environment** (``workflow/envs/env.yaml``):

Key dependencies are automatically managed:

- bwameth (≥0.2.7)
- bwa-mem2 (≥2.2.1)
- biscuit (≥1.2.1)
- samtools (≥1.17)
- fastp (≥0.23.2)
- multiqc (≥1.14)
- mark-nonconverted-reads (≥1.2)
- wgbs_tools (external dependency)

Advanced Configuration
----------------------

**Resource Limits**

Modify resource requirements in individual rules:

.. code-block:: python

   # Example: Increase memory for alignment
   resources:
      mem_mb = 128000  # 128GB RAM

**Trimming Parameters**

Customize trimming in the fastp rule:

.. code-block:: python

   # fastp trimming parameters
   minimum_length = 15
   trim_r1_5prime = "10"
   trim_r1_3prime = "10"

**Methylation Calling Parameters**

Adjust biscuit parameters:

.. code-block:: python

   # biscuit bed generation (in biscuit_bed rule)  
   minimum_reads = 3  # Minimum coverage per CpG site

**Non-conversion Detection**

Configure mark-nonconverted-reads:

.. code-block:: python

   # mark_nonconverted rule
   threshold = 3  # Minimum non-converted Cs to flag read

Validation
----------

**Test Configuration**

Use the provided test dataset:

.. code-block:: bash

   # Test with provided test.csv
   snakemake --cores 4 --use-conda --dry-run

**Sample Validation**

The pipeline validates:

- Required columns are present in CSV files
- MD5 checksums match input files  
- File paths are accessible
- Method specification is valid ("emseq" or "bs-seq")

Troubleshooting Configuration
-----------------------------

**Common Issues:**

1. **Missing files**: Ensure FASTQ paths are correct relative to sample directories
2. **MD5 mismatches**: Verify file integrity and checksums
3. **Method specification**: Use exactly "emseq" or "bs-seq" (case-sensitive)
4. **CSV format**: Ensure proper comma separation and no extra whitespace

**Subsampled Data Notes:**

- Subsampled runs override path_R1/path_R2 with "R1.fastq.gz"/"R2.fastq.gz"
- MD5 validation is skipped for subsampled data
- Original data structure is preserved with "_subsampled" suffix

Next Steps
----------

After configuration, proceed to :doc:`usage` to run the pipeline.
