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
     --rerun-triggers mtime \       # Rerun when files are modified
     --keep-going \                 # Continue on non-critical errors
     --dry-run                      # Show what would be executed (test mode)

Pipeline Modes
--------------

**Standard Mode**
   Processes full datasets with complete analysis.

**Subsampled Mode**
   For rapid testing and QC with reduced data:

   .. code-block:: bash

      # Generate subsampled data (5M reads per sample)
      snakemake --cores 100 --use-conda --until seqtk_subsample
      
      # Run analysis on subsampled data
      snakemake --cores 100 --use-conda --config subsampled=True

Performance Optimization
-------------------------

**Resource Management**

The pipeline automatically detects available CPU cores but you can optimize based on your system:

.. code-block:: bash

   # For high-memory systems
   snakemake --cores 50 --use-conda --resources mem_mb=250000
   
   # Specify temporary directory for large intermediate files
   snakemake --cores 20 --use-conda --default-resources "tmpdir='/scratch/tmp/'"

**Cluster Execution**

For cluster environments, use appropriate profiles:

.. code-block:: bash

   # Example for SLURM
   snakemake --cores 100 --use-conda --cluster "sbatch -t 24:00:00 -c {threads} --mem {resources.mem_mb}"

Monitoring Progress
-------------------

**Real-time Monitoring**

.. code-block:: bash

   # Enable detailed logging
   snakemake --cores 4 --use-conda --printshellcmds --reason
   
   # Generate execution report
   snakemake --cores 4 --use-conda --report report.html

**Notifications**

The pipeline includes optional notifications via ntfy.sh. These can be disabled by removing the curl commands in the Snakefile.

Resuming Interrupted Runs
--------------------------

The pipeline is designed to resume gracefully:

.. code-block:: bash

   # Resume with incomplete job rerun
   snakemake --cores 4 --use-conda --rerun-incomplete
   
   # Force rerun of specific samples
   snakemake --cores 4 --use-conda --forcerun sample_name

Common Workflows
----------------

**Full Production Run**
   Process all samples with complete analysis and QC.

**QC-focused Run**
   Generate subsampled data for rapid quality assessment.

**Specific Sample Processing**
   Target specific samples using Snakemake's target specification.

Next Steps
----------

- Review :doc:`output_format` to understand pipeline outputs
- See :doc:`troubleshooting` for common issues and solutions
- Check :doc:`pipeline_details` for technical implementation details
