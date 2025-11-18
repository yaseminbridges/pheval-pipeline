# Exomiser PhEval Pipeline

This repository provides a Nextflow pipeline for running and benchmarking the phenotype-driven variant prioritisation tool [Exomiser](https://github.com/exomiser/Exomiser) within the [PhEval](https://github.com/monarch-initiative/pheval) evaluation framework.

The workflow brings together all phases of a benchmarking run into one reproducible pipeline:
	•	**Data preparation** - builds Exomiser configuration directories and corpus structures (phenopackets + VCFs).
	•	**Runner** - runs Exomiser across all defined configuration–corpus combinations.
	•	**Analysis** - runs the benchmark to generate performance plots, summary statistics, and evaluation metrics for all Exomiser runs.

This pipeline streamlines the entire process from raw inputs to fully benchmarked outputs — in a single command, providing a consistent and reproducible framework for large-scale Exomiser evaluations.


## Installation

Clone this repository:

```bash
git clone https://github.com/yaseminbridges/pheval-pipeline.git
cd pheval-pipeline
```

## Container / Environment Setup

The pipeline can be run with either Apptainer/Singularity (HPC profile) or Conda (local profile).

### Option 1: Apptainer/Singularity (HPC)

If you are running on an HPC environment with Apptainer/Singularity, build the .sif container:

```bash
mkdir sif
apptainer build sif/pheval-exomiser-0.6.5.sif modules/tools/exomiser/containers/pheval-exomiser.def
```

### Option 2: Conda (Local)

If you are running locally and prefer Conda, no .sif file is required.
The pipeline will create and use a Conda environment automatically.

## Configuration

Pipeline behaviour and inputs are controlled through the `nextflow.config` file.  
The key parameters are defined inside the `params { ... }` block.

### Example `nextflow.config`

```groovy
params {

  // --- Output directories (auto-created by the pipeline) ---
  configurations_dir = "${projectDir}/configurations"  // Exomiser configuration directories
  corpora_dir        = "${projectDir}/corpora"         // Corpora staging directories (phenopackets + VCFs)
  results_dir        = "${projectDir}/results"         // Exomiser runner outputs (raw results + pheval standardised results)
  benchmark_dir      = "${projectDir}/benchmark"       // Benchmark outputs (YAML configuration + plots + stats)

  // --- Input resources ---
  exomiser_data_dir        = "/exomiser/data" // Exomiser databases (phenotype/hg19/hg38)
  exomiser_distribution_dir = "/exomiser/distribution"   // Path to unpacked Exomiser distribution
  exomiser_config_template = "${projectDir}/configs/exomiser_config_template.yml" // Template used to build each config.yaml

  // --- Exomiser run configurations ---
  // Each entry defines one run setup (db versions, presets, etc.)
  exomiser_configs = [
    [
        config_id: "exomiser-14.1.0/2508_all",              // Unique identifier for this run (used in directory naming)
        exomiser_version: "14.1.0",                         // Exomiser version
        phenotype_db: "2508",                               // Phenotype DB version
        hg19_db: "2508",                                    // hg19 genome DB version
        hg38_db: "2508",                                    // hg38 genome DB version
        exomiser_analysis: "preset-exome-analysis.yml"                 // Preset configuration file located in ./modules/tools/exomiser/presets
    ],
    [
        config_id: "exomiser-14.1.0/2508_human_only",
        exomiser_version: "14.1.0",
        phenotype_db: "2508",
        hg19_db: "2508",
        hg38_db: "2508",
        exomiser_analysis: "preset-exome-analysis_human_only.yml"
    ]
  ]

  // --- Input corpora ---
  // Each corpus corresponds to a set of phenopackets and (optionally) VCFs
  corpora_configs = [
      [
          corpora_id: "LIRICAL",                             // Corpus identifier
          phenopacket_directory: "/LIRICAL/phenopackets", // Path to phenopackets
          vcf_directory: "/LIRICAL/vcf",                   // Path to VCFs
      ],
      [
          corpora_id: "HEART_FAILURE",
          phenopacket_directory: "/HEART_FAILURE/phenopackets",
          vcf_directory: "/HEART_FAILURE/vcf",
      ]
  ]
}

profiles {
  // Local execution (defaults to Conda environment, no container needed)
  local {
    includeConfig 'conf/local.config'
  }

  // HPC execution (uses Apptainer/Singularity + SGE directives)
  hpc {
    includeConfig 'conf/hpc.config'
  }
}
```

### Exomiser Template Configuration

In addition to nextflow.config, the behaviour of each Exomiser run is controlled by a template file located at `configs/exomiser_config_template.yml`

This file is copied and populated for each run based on the parameters you define in `nextflow.config`.
It exposes the key analysis options that users may want to customise.

Example exomiser_config_template.yml:

```yaml
tool: exomiser
tool_version: {{EXOMISER_VERSION}}
# Toggle analysis modes
variant_analysis: True        # Set to False to disable VCF-based analysis
gene_analysis: True
disease_analysis: False       # Set to True to include disease-level benchmarking

tool_specific_configuration_options:
  environment: local
  exomiser_software_directory: exomiser-cli-{{EXOMISER_VERSION}}
  analysis_configuration_file: {{PRESET}}
  max_jobs: 0
  application_properties:
    remm_version:
    cadd_version:
    hg19_data_version: "{{HG19_VERSION}}"
    hg19_local_frequency_path:
    hg19_whitelist_path:
    hg38_data_version: "{{HG38_VERSION}}"
    hg38_local_frequency_path:
    hg38_whitelist_path:
    phenotype_data_version: "{{PHENO_VERSION}}"
    cache_type: caffeine       # Change cache backend if required
    cache_caffeine_spec: 1000000

  output_formats: [JSON, HTML] # Add/remove formats (e.g. TSV_GENE, TSV_VARIANT, VCF)
  post_process:
    score_name: combinedScore
    sort_order: DESCENDING
```


## Running the Pipeline

Once configuration is complete, the pipeline can be launched with a single command.

Example (HPC with Apptainer/Singularity)

```bash
nextflow run main.nf -profile hpc
```

Example (Local with Conda)

```bash
nextflow run main.nf -profile local
```

Outputs

The pipeline automatically organises outputs into the following directories:
	•	configurations/ – Prepared Exomiser configuration directories
	•	corpora/ – Staging area for phenopackets and VCFs
	•	results/ – Results of all Exomiser runs (raw and PhEval-standardised)
	•	benchmark/ – Benchmark results, including plots, summary statistics, and evaluation metrics

Benchmarks are corpus-specific: for each corpus, a YAML configuration file and corresponding plots/statistics are created.


