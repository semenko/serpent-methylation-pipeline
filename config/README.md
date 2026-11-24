# Configuration

There is no configuration file yet: `config/config.yaml` is a placeholder and is not read. (PRs welcome!)

## General Settings

- Pipeline parameters (trimming lengths, thresholds, threads, memory) are set in the rules in `workflow/Snakefile`.
- Run modes are set on the command line with `--config`:
  - `make-subsampled=True`: only generate subsampled reads
  - `analyze-subsampled=True`: run the pipeline on the subsampled reads
  - `bam2tensor=True`: also export [bam2tensor](https://github.com/mcwdsi/bam2tensor) tensors (needs `pip install bam2tensor`)
  - `ntfy_topic=TOPIC`: send [ntfy.sh](https://ntfy.sh) notifications to this topic (off by default)

## Sample Definition

It is critical to define your samples correctly in `data/EXPERIMENT.csv`. A working example is provided as `data/test.csv`. Every `.csv` in `data/` is run.

You *must* provide, for each sample:

- `sample_id`: a name for the sample, unique across all experiments. Reads are expected in `data/EXPERIMENT/SAMPLE_ID/raw/`.
- `path_R1` and `path_R2`: filenames of your paired R1/R2 `.fastq.gz` in that `raw/` directory
- `method`: `emseq` or `bsseq` (case, hyphens and underscores are ignored)
- `md5sum_R1` and `md5sum_R2`: known MD5 sums of your `.fastq.gz` files

Rows missing any of these are skipped with a warning. All other columns are optional and ignored by the pipeline.
