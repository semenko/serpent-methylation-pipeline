Installation
============

System Requirements
-------------------

* **Operating System**: Linux (macOS not currently supported due to dependency limitations)
* **Memory**: Minimum 32GB RAM recommended (64GB+ for large datasets)
* **Storage**: 100GB+ available space for reference genomes and intermediate files
* **CPU**: Multi-core processor recommended (pipeline scales with available cores)

Prerequisites
-------------

Before installing the Serpent Methylation Pipeline, you need:

1. **Conda/Mamba Package Manager**

   We recommend using `mamba <https://github.com/conda-forge/miniforge>`_ for faster dependency resolution:

   .. code-block:: bash

      # Install Miniforge (includes mamba)
      curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
      bash Miniforge3-$(uname)-$(uname -m).sh

2. **Git** (for cloning the repository)

3. **wgbs_tools** (manual install)

   `wgbs_tools <https://github.com/nloyfer/wgbs_tools>`_ is not available from conda, so it is not part of
   ``workflow/envs/env.yaml``. The ``wgbs_tools_pat_beta`` rule expects:

   * ``wgbstools`` on your ``PATH``
   * a genome named ``GRCh38-DAC-U2AF1`` already initialized against the masked reference, e.g.
     ``wgbstools init_genome GRCh38-DAC-U2AF1 --fasta_path data/reference/GRCh38-DAC-U2AF1.fna``
     (the masked reference is built by the pipeline's ``mask_reference_fasta`` rule)

Installation Steps
------------------

1. **Clone the Repository**

   .. code-block:: bash

      git clone https://github.com/semenko/serpent-methylation-pipeline.git
      cd serpent-methylation-pipeline

2. **Install Snakemake**

   .. code-block:: bash

      mamba install -c bioconda -c conda-forge snakemake snakemake-storage-plugin-http

3. **Create Pipeline Environment (Optional)**

   With ``--use-conda``, Snakemake builds the environment in ``workflow/envs/env.yaml`` for you.
   To create it by hand instead (and run without ``--use-conda``):

   .. code-block:: bash

      mamba env create -n serpent_pipeline_env -f workflow/envs/env.yaml
      conda activate serpent_pipeline_env

4. **Verify Installation**

   Test that the pipeline can run:

   .. code-block:: bash

      snakemake --cores 4 --use-conda --dry-run

   This should show the pipeline execution plan (21 jobs for the bundled test sample) without errors.
   The dry run needs network access: Snakemake checks that the reference download URLs exist.

Docker/Singularity Support
--------------------------

Currently, the pipeline is designed to run with conda environments. Docker/Singularity support may be added in future versions.

Troubleshooting Installation
-----------------------------

**Common Issues:**

* **Mac OS Compatibility**: Several critical dependencies (like ``bwa-mem2``) don't support Mac OS architectures. Consider using a Linux virtual machine or cloud instance.

* **Memory Issues**: If you encounter out-of-memory errors, ensure you have sufficient RAM and adjust the memory parameters in the Snakefile.

* **Network Issues**: The pipeline downloads reference genomes on first run. Ensure you have a stable internet connection and sufficient disk space.

Next Steps
----------

After installation, proceed to :doc:`configuration` to set up your data and run the pipeline.
