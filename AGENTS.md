# AGENTS.md

Instructions for AI coding agents working in this repository. Humans should start with [README.md](README.md).

## What this is

A Snakemake pipeline that takes paired-end WGBS / EM-seq `.fastq.gz` files to methylation calls and QC. It is run by hand on large Linux servers against human data. There is no application, package or unit test suite: the product is `workflow/Snakefile`.

## Layout

| Path | Purpose |
| --- | --- |
| `workflow/Snakefile` | The entire pipeline: sample parsing, then every rule. |
| `workflow/envs/env.yaml` | The single conda environment shared by all rules. |
| `workflow/analyze-subsamples.sh` | Convenience script for the two subsampling steps. |
| `data/*.csv` | One file per experiment. Each row is a sample. `data/test.csv` is the bundled test. |
| `data/EXPERIMENT/SAMPLE/raw/` | Input reads. Everything else under `data/` is pipeline output. |
| `config/` | Placeholder. `config.yaml` is not read by anything. |
| `docs/` | Sphinx docs (reStructuredText), deployed to GitHub Pages by `.github/workflows/docs.yml`. |
| `.github/workflows/main.yml` | CI: snakefmt via super-linter, `snakemake --lint`, and a dry run. |
| `.github/linters/.snakefmt.toml` | snakefmt settings (strings are not normalized). |

## Checks

There is no way to run the pipeline for real in a development environment, so these checks are the test suite. Run all of them after any change to `workflow/`. They work on Linux and macOS and need network access (Snakemake checks that the reference URLs exist).

```bash
pip install snakemake snakemake-storage-plugin-http pandas snakefmt

# 1. The DAG must build in all three modes
snakemake --cores 4 --dry-run                                    # expect 21 jobs
snakemake --cores 4 --dry-run --config make-subsampled=True      # expect 3 jobs
snakemake --cores 4 --dry-run --config analyze-subsampled=True   # expect 22 jobs

# 2. Lint. Pre-existing warnings are fine; do not add new ones.
snakemake --lint

# 3. Formatting (CI enforces this)
snakefmt --config .github/linters/.snakefmt.toml --check workflow/Snakefile
```

The job counts are for a fresh checkout, where the only experiment is `data/test.csv`. If you change the rule graph on purpose, update the counts here.

After any change to `docs/`:

```bash
pip install -r docs/requirements.txt
sphinx-build -W --keep-going -b html docs docs/_build/html   # must finish with no warnings
```

## Rules for working here

- **Never start a real run** (anything without `--dry-run` or `--lint`) to test a change. It downloads GRCh38, builds indices for hours, and needs roughly 128 GB of RAM. Ask the user to run it instead.
- **Keep one Snakefile.** The single-file layout is a deliberate choice (see the header comment). Do not split it into modules, wrappers or per-rule environments.
- **Do not change scientific behavior unasked.** Trimming lengths, the non-conversion threshold, minimum coverage, the reference build and masking, aligner flags and tool choices are decisions the author made from QC on real data. If one looks wrong, report it instead of changing it.
- **Do not touch data.** Never edit, move or delete anything under `data/` except experiment `.csv` files. Final `.bam` files are write-protected on purpose.
- **Do not rename outputs or bump `.pipeline-complete-v2` casually.** Existing users have completed runs on disk; renaming an output makes Snakemake redo days of compute. Bump the completion flag only when existing outputs really must be regenerated.
- **Keep docs in step.** A behavior change is not finished until `README.md`, `config/README.md` and the matching page in `docs/` say the same thing as the Snakefile. The Snakefile is the source of truth when they disagree.
- **Verify URLs before adding them.** Reference downloads have broken before when NCBI moved files.
- Do not commit or push unless asked.

## Things that will trip you up

- **`{DATA_PATH}` is a Snakemake wildcard, not an f-string.** Rule paths are written `"{DATA_PATH}/{experiment}/{sample}/..."` with no `f` prefix. The targets in `rule all` are f-strings built from the global `DATA_PATH`, and Snakemake matches the wildcard against them. Inside `shell:` blocks, `{DATA_PATH}` resolves to the global. Follow the existing pattern in new rules.
- **`DATA_PATH` is not normalized** (`.../workflow/../data`). Targets given on the command line must be spelled the same way.
- **Samples are looked up by `sample_id` alone** (`all_experiments_df.loc[wildcards.sample, ...]`), which is why IDs must be unique across experiments.
- **Subsampling is driven by the experiment name.** `analyze-subsampled` renames every experiment to `EXPERIMENT_subsampled`. For those, `raw_fastq()` returns `R1/R2.fastq.gz`, the `md5sum` rule is excluded by a wildcard constraint, and `seqtk_subsample` is what produces the reads and the md5 marker files.
- **The alignment core is one piped job group** (`align_core`): `fastp` → `bwa_meth` → `mark_nonconverted` → `samtools_fixmate_sort_markdup`, connected by `pipe()` outputs. All four run at once and Snakemake sums their threads, so `align_core_threads()` splits the `--cores` budget between them (at least 4 cores are needed). Adding a rule in the middle means adding it to the group and to that budget.
- **`ancient()` is used on reference and index inputs** so that touching a reference file does not trigger re-alignment of everything.
- **Not every rule is wired in.** `biscuit_epiread` and `wgbs_tools_index` exist but nothing depends on them, and a biscuit alignment rule is commented out. `touch_complete_flag` lists what a finished sample requires.
- **`wgbstools` is not in `env.yaml`** (it is not on conda). `wgbs_tools_pat_beta` assumes it is on `PATH` with a `GRCh38-DAC-U2AF1` genome initialized.
- **Linux-only at run time.** `md5sum`, `bwa-mem2` and others are unavailable on macOS, though dry runs work anywhere.
- **Config flags are read through `config_flag()`**, which requires a true value. Use it for new flags instead of `"name" in config`.
- **Notifications** are off unless `--config ntfy_topic=...` is set. They go to ntfy.sh through `NTFY_TOPIC` and must stay best-effort (`|| true`): a failed `curl` must never fail a job.

## Style

- Python and Snakemake code is formatted with snakefmt (black style, existing quote style preserved).
- Keep the explanatory comments. Much of the file's value is the recorded reasoning behind each choice.
- Each rule logs to `{DATA_PATH}/{experiment}/{sample}/logs/` and redirects stderr there.
