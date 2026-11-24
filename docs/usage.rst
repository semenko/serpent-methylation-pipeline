Usage Guide
===========

Basic Usage
-----------

The Serpent Methylation Pipeline follows a simple workflow:

1. **Prepare your data** (see :doc:`configuration`)
2. **Run the pipeline**
3. **Analyze results**

Quick Start Example
-------------------

.. code-block:: bash

   # Navigate to pipeline directory
   cd serpent-methylation-pipeline
   
   # Test run (dry-run mode)
   snakemake --cores 4 --use-conda --dry-run
   
   # Full pipeline execution
   snakemake --cores 4 --use-conda --printshellcmds --rerun-incomplete

Command Line Options
--------------------

Essential Snakemake parameters for this pipeline:

.. code-block:: bash

   snakemake \
     --cores 4 \                    # Number of CPU cores to use
     --use-conda \                  # Use conda environments
     --printshellcmds \             # Print shell commands (recommended)
     --rerun-incomplete \           # Rerun incomplete jobs
     --rerun-triggers mtime \       # Only rerun when input files are newer (ignore code/param changes)
     --keep-going \                 # Keep running independent jobs after a failure
     --dry-run                      # Show what would be executed (test mode)

Pipeline Modes
--------------

**Standard Mode**
   Processes full datasets with complete analysis.

**Subsampled Mode**
   For rapid testing and QC with reduced data:

   .. code-block:: bash

      # Generate subsampled data (5M read pairs per sample) in data/EXPERIMENT_subsampled/
      snakemake --cores 100 --use-conda --config make-subsampled=True

      # Run the whole analysis on the subsampled data only
      snakemake --cores 100 --use-conda --config analyze-subsampled=True

   ``workflow/analyze-subsamples.sh`` runs both steps. ``analyze-subsampled`` generates any
   subsampled reads that are missing, so the first step is optional.

Performance Optimization
-------------------------

**Resource Management**

Trimming, alignment, non-conversion marking and sorting run together as one piped job group that shares
``--cores`` (alignment gets everything the others don't need), so the pipeline needs **at least 4 cores**.
Rules declare their memory needs as ``mem_mb`` resources, which you can cap:

.. code-block:: bash

   # Never schedule jobs that together need more than 250GB of RAM
   snakemake --cores 50 --use-conda --resources mem_mb=250000
   
   # Specify temporary directory for large intermediate files
   snakemake --cores 20 --use-conda --default-resources "tmpdir='/scratch/tmp/'"

**Cluster Execution**

Snakemake 8+ submits cluster jobs through `executor plugins <https://snakemake.github.io/snakemake-plugin-catalog/>`_
(the old ``--cluster`` flag was removed):

.. code-block:: bash

   # Example for SLURM
   pip install snakemake-executor-plugin-slurm
   snakemake --executor slurm --jobs 20 --use-conda --default-resources slurm_account=<account>

Monitoring Progress
-------------------

**Real-time Monitoring**

.. code-block:: bash

   # Print each shell command as it runs
   snakemake --cores 4 --use-conda --printshellcmds

   # Generate an execution report after a run
   snakemake --report report.html

**Notifications**

The pipeline can send best-effort `ntfy.sh <https://ntfy.sh>`_ push notifications (per finished sample, and on overall
success/failure). They are off by default and include the hostname and output path. To turn them on, set a topic:

.. code-block:: bash

   snakemake --cores 4 --use-conda --config ntfy_topic=my-private-topic

Resuming Interrupted Runs
--------------------------

The pipeline is designed to resume gracefully:

.. code-block:: bash

   # Resume with incomplete job rerun
   snakemake --cores 4 --use-conda --rerun-incomplete
   
   # Force a rule (and everything downstream of it) to rerun
   snakemake --cores 4 --use-conda --forcerun biscuit_bed

Final ``.bam`` files are write-protected. To realign a sample, delete everything in its directory except ``raw/``.

Common Workflows
----------------

**Full Production Run**
   Process all samples with complete analysis and QC.

**QC-focused Run**
   Generate subsampled data for rapid quality assessment.

**Specific Sample Processing**
   Request a sample's completion flag as the target, e.g.
   ``snakemake --cores 4 --use-conda workflow/../data/EXPERIMENT/SAMPLE/.pipeline-complete-v2``
   (targets must be spelled the way the Snakefile builds them, starting ``workflow/../data/``).

Next Steps
----------

- Review :doc:`output_format` to understand pipeline outputs
- Check :doc:`pipeline_details` for technical implementation details
