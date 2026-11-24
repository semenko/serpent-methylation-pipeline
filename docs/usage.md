# Usage Guide

All commands are run from the repository root.

## Running the Pipeline

```bash
# Show what would run, without running it
snakemake --cores 4 --use-conda --dry-run

# Run every sample in every experiment
snakemake --cores 4 --use-conda --printshellcmds --rerun-incomplete --keep-going --rerun-triggers mtime
```

| Option | Meaning |
| --- | --- |
| `--cores N` | CPU cores to use. At least 4 are needed; give it as many as you have. |
| `--use-conda` | Build and use the tool environment in `workflow/envs/env.yaml` |
| `--printshellcmds` | Print each shell command as it runs |
| `--rerun-incomplete` | Redo jobs that were interrupted |
| `--keep-going` | Keep running independent jobs after one fails |
| `--rerun-triggers mtime` | Only rerun a job when its inputs are newer than its outputs. Without this, Snakemake also reruns finished jobs whenever a rule's code or parameters change, such as after updating the pipeline. |
| `--dry-run` | Show the plan only |

## Subsampled Runs

For a quick look at library quality, the pipeline can run on a subsample of 5M read pairs per sample.
Subsampled data lives in a parallel `data/EXPERIMENT_subsampled/` directory with the same layout.

```bash
# Write the subsampled reads, and nothing else
snakemake --cores 100 --use-conda --config make-subsampled=True

# Run the whole analysis on the subsampled reads only
snakemake --cores 100 --use-conda --config analyze-subsampled=True
```

`analyze-subsampled` generates any subsampled reads that are missing, so the first command is optional.
`workflow/analyze-subsamples.sh` runs both.

## bam2tensor Export (Optional)

[bam2tensor](https://github.com/mcwdsi/bam2tensor) converts each final `.bam` into a sparse read-by-CpG
matrix for machine learning. Install it with `pip install bam2tensor` (see [Installation](installation.md)), then add the flag:

```bash
snakemake --cores 16 --use-conda --config bam2tensor=True
```

Each sample gets `bam2tensor/SAMPLE.methylation.npz` (see [Output Format](output_format.md)). The flag can be added to a
run that has already finished: only the missing tensors are built. It combines with `analyze-subsampled=True`
and is ignored with `make-subsampled=True`.

## Resources

Trimming, alignment, non-conversion marking and sorting run together as one piped job group that shares
`--cores` (alignment gets everything the others do not need). That is why at least 4 cores are needed.

Rules declare their memory needs as `mem_mb` resources. Snakemake only acts on them if you give it a limit:

```bash
# Never run jobs that together need more than 250 GB of RAM
snakemake --cores 50 --use-conda --resources mem_mb=250000

# Put large temporary files (from sorting) on scratch space
snakemake --cores 20 --use-conda --default-resources "tmpdir='/scratch/tmp/'"
```

**Clusters.** Snakemake 8+ submits cluster jobs through
[executor plugins](https://snakemake.github.io/snakemake-plugin-catalog/) (the old `--cluster` flag is gone):

```bash
pip install snakemake-executor-plugin-slurm
snakemake --executor slurm --jobs 20 --use-conda --default-resources slurm_account=<account>
```

## Notifications

The pipeline can send best-effort [ntfy.sh](https://ntfy.sh) push notifications: one per finished sample, and
one on overall success or failure. They are off by default, and include the hostname and output path.
Anyone who knows a topic name can read it, so choose one that is hard to guess:

```bash
snakemake --cores 4 --use-conda --config ntfy_topic=my-private-topic
```

## Resuming and Redoing

Rerunning the same command resumes where it stopped.

```bash
# Force a rule, and everything downstream of it, to rerun
snakemake --cores 4 --use-conda --forcerun biscuit_bed

# Run a single sample, by asking for its completion flag
snakemake --cores 4 --use-conda workflow/../data/EXPERIMENT/SAMPLE/.pipeline-complete-v2
```

Targets must be spelled the way the Snakefile builds them, starting with `workflow/../data/`.

Final `.bam` files are write-protected. To redo a sample from scratch, delete everything in its directory
except `raw/`.

## Next Steps

- [Output Format](output_format.md) describes what the pipeline writes
- [Pipeline Details](pipeline_details.md) explains how and why each step is done
