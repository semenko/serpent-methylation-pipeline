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

   We recommend using `mamba <https://github.com/conda-forge/miniforge#mambaforge>`_ for faster dependency resolution:

   .. code-block:: bash

      # Install mambaforge
      curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-$(uname)-$(uname -m).sh"
      bash Mambaforge-$(uname)-$(uname -m).sh

2. **Git** (for cloning the repository)

Installation Steps
------------------

1. **Clone the Repository**

   .. code-block:: bash

      git clone https://github.com/semenko/serpent-methylation-pipeline.git
      cd serpent-methylation-pipeline

2. **Install Snakemake**

   .. code-block:: bash

      mamba install -c bioconda -c conda-forge snakemake snakemake-storage-plugin-http

3. **Create Pipeline Environment (Optional but Recommended)**

   .. code-block:: bash

      mamba env create -n serpent_pipeline_env -f workflow/envs/env.yaml
      conda activate serpent_pipeline_env

4. **Verify Installation**

   Test that the pipeline can run:

   .. code-block:: bash

      snakemake --cores 4 --use-conda --dry-run

   This should show the pipeline execution plan without errors.

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
