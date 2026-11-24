# Sphinx configuration: https://www.sphinx-doc.org/en/master/usage/configuration.html
import subprocess

project = "Serpent Methylation Pipeline"
author = "Nick Semenkovich"
copyright = "2023-2026, Nick Semenkovich"


def git_version():
    """The latest release tag (e.g. 1.0.0), so the version here cannot drift from the releases."""
    try:
        tag = subprocess.run(
            ["git", "describe", "--tags", "--abbrev=0"],
            capture_output=True,
            text=True,
            check=True,
        ).stdout.strip()
        return tag.lstrip("v")
    except (OSError, subprocess.CalledProcessError):
        return ""  # No git, or a shallow clone without tags


release = version = git_version()

# Pages are written in Markdown (MyST)
extensions = ["myst_parser", "sphinx.ext.githubpages"]
exclude_patterns = ["_build", "Thumbs.db", ".DS_Store"]

html_theme = "furo"
html_title = project
html_logo = "../serpent-logo.png"
html_theme_options = {
    "source_repository": "https://github.com/semenko/serpent-methylation-pipeline/",
    "source_branch": "main",
    "source_directory": "docs/",
}
