Installation
============

System Requirements
-------------------

* **Operating system**: Linux. Several dependencies (such as ``bwa-mem2``) are not built for macOS, although
  dry runs work anywhere.
* **Memory**: about 128 GB. Rules ask for up to 128 GB (``biscuit_bed``); alignment and sorting ask for 72 GB and 64 GB.
* **CPU**: at least 4 cores. Alignment uses every core it is given.
* **Storage**: the reference and its indices are built once in ``data/reference/``. Each sample needs room for
  its ``.bam`` and, while it is being sorted, for temporary files of similar size.
* **Network**: the reference is downloaded on the first run, and even a dry run checks that the download URLs exist.

Installation Steps
------------------

1. **Install mamba (or conda)**

   `Miniforge <https://github.com/conda-forge/miniforge>`_ provides both:

   .. code-block:: bash

      curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
      bash Miniforge3-$(uname)-$(uname -m).sh

2. **Clone the repository**

   .. code-block:: bash

      git clone https://github.com/semenko/serpent-methylation-pipeline.git
      cd serpent-methylation-pipeline

3. **Install Snakemake** (8 or newer)

   .. code-block:: bash

      mamba install -c conda-forge -c bioconda snakemake snakemake-storage-plugin-http

   With ``--use-conda``, Snakemake builds the tool environment in ``workflow/envs/env.yaml`` for you on the first run.

4. **Check the installation**

   .. code-block:: bash

      snakemake --cores 4 --use-conda --dry-run

   This prints the execution plan (21 jobs for the bundled test sample) without running anything.

5. **Install wgbs_tools by hand**

   `wgbs_tools <https://github.com/nloyfer/wgbs_tools>`_ is not available from conda, so it is not part of
   ``env.yaml``. Follow its instructions so that ``wgbstools`` is on your ``PATH``. It also needs a genome named
   ``GRCh38-DAC-U2AF1``, made from the masked reference that the pipeline builds. Build that reference first, then
   initialize the genome:

   .. code-block:: bash

      snakemake --cores 4 --use-conda workflow/../data/reference/GRCh38-DAC-U2AF1.fna
      wgbstools init_genome GRCh38-DAC-U2AF1 --fasta_path data/reference/GRCh38-DAC-U2AF1.fna

6. **Install bam2tensor (optional)**

   Only needed for ``--config bam2tensor=True`` (see :doc:`usage`). It is on PyPI, not conda:

   .. code-block:: bash

      pip install bam2tensor

Next Steps
----------

Continue to :doc:`configuration` to define your samples.
