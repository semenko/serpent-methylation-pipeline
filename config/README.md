To configure this workflow, currently you can edit `workflow/Snakefile` to specify the files you want to operate on.

# General Settings

(In the future, I'll add a .yaml to specify configuration files, PR's welcome!)

# Sample Definition

It is critical to define your samples correctly in `data/EXPERIMENT.csv`, and a working sample as `data/test.csv` is provided.

* You *must* provide (at the least):
  * sample_id (an arbitrary name for the sample)
  * path_R1 & path_R2 (path to your paired R1/R2 .fastq.gz)
  * method (em-seq or bs-seq)
  * md5sum_R1 & md5sum_R2 (known MD5 sums of your .fastq.gz's)
 
All other columns are optional.
