# PhEval Pipeline

This repository provides a Nextflow pipeline for running and benchmarking the phenotype-driven prioritisation tools within the [PhEval](https://github.com/monarch-initiative/pheval) evaluation framework.


The workflow brings together all phases of a benchmarking run into one reproducible pipeline:
* **Data preparation** - builds tool configuration directories and corpus structures (phenopackets + VCFs). 
* **Runner** - runs tools across all defined configuration–corpus combinations.
* **Analysis** - runs the benchmark to generate performance plots, summary statistics, and evaluation metrics for all Exomiser runs.

This pipeline streamlines the entire process from raw inputs to fully benchmarked outputs — in a single command, providing a consistent and reproducible framework for large-scale evaluations.


## Installation

Clone this repository:

```bash
git clone https://github.com/yaseminbridges/pheval-pipeline.git
cd pheval-pipeline
```

## Adding a New Tool to the PhEval Pipeline

Tools implemented in the pipeline live under:

`module/tools`

Each tool must follow a standard structure:

```tree
tool
├── containers
│   └── pheval-TOOL.def # (Optional) Singularity recipe for the tool’s runtime container
├── envs
│   └── pheval-TOOL.yml  # (Optional) Conda environment if not using a container
├── toolPrepareConfigurations.nf # Required: creates configuration directories for the specific tool (--input-dir for pheval run coommand)
├── toolRunner.nf # Required: runs the tool via the pheval run command
└── tool_config_template.yml # Required: template for creating the config.yaml as required by pheval.
```

Below is what each file must contain and how it plugs into the pipeline.

### 1. File Responsibilities

#### toolPrepareConfigurations.nf (required)

Every tool must implement its own toolPrepareConfigurations.nf using the same input/output interface, so that the main workflow can automatically integrate it.

##### Required Inputs & Outputs

Input:

```
tuple val(cfg)
```

Where cfg is one entry from `params.tools` in the `nextflow.config`.

It contains fields such as:
- `config_id`
- `tool`
- `version`
- tool specific paths / parameters needed for configuration
- `config_template` (path to the tool’s template YAML)

Output:

```
tuple val(cfg), path('<config_id>'), emit: cfg
```

This exact output structure is required so the rest of the workflow can combine configurations with corpora and pass the results to the tool runner.

##### What `toolPrepareConfigurations.nf` must do

Each tool’s preparation script must:

1. Create a directory named exactly: `<configurations_dir>/<config_id>/`
2. Load the tool’s YAML template, defined in: `cfg.config_template`
3. Substitute template fields using values in cfg
4. Write the final config.yaml to `<configurations_dir>/<config_id>/`
5. Prepare the full tool-specific input directory. 
6. Ensure all required assets live inside `<config_id>/`, for example:
   * config.yaml 
   * databases 
   * JAR files 
   * ontology files 
   * reference matrices 
   * analysis configuration files

(whatever is required for your tool’s PhEval runner to execute)


#### toolRunner.nf (required)

Each tool must provide a `toolRunner.nf` that defines how the tool is executed via pheval run.

This process is responsible for running the tool on each corpus.

##### Required Inputs & Outputs

Input:

```
tuple val(cfg), val(corpus)
```

This tuple is created in the main workflow using:

```
runTOOLRunner(prepared_configs.cfg.combine(corpora_ch.corpus))
```

Meaning:
* cfg → one prepared configuration for the tool 
* corpus → one corpus produced by prepareCorpora 
* .combine() pairs every configuration with every corpus, so the runner must accept both values.

Output:

```
tuple val(cfg), path('<config_id>'), emit: cfg
```

This structure is required so the benchmark stage can identify all run results per corpus/tool.

##### What `toolRunner.nf` Must Do

Each tool’s runner must:
1. Load the correct execution environment (Singularity container or conda env declared in hpc.config)
2. Create the output directory: `<results_dir>/<config_id>/<corpus_id>/`
3. Call `pheval run` exactly like:
```bash
pheval run \
  -i <prepared_config_dir> \
  -r <runner_name> \
  -t <corpus_directory> \
  -o <results_output_dir> \
  -v <tool_version>
```
##### Important: Do not modify the calling structure in `main.nf`

All tools must be compatible with being called as:
```
runToolRunner(prepared_configs.cfg.combine(corpora_ch.corpus))
```

Therefore:
* `toolPrepareConfigurations.nf` must emit tuple val(cfg), path(...)
* `toolRunner.nf` must accept tuple val(cfg), val(corpus)
* Output must follow the required format so the workflow can concatenate results and benchmark.

This guarantees new tools behave identically to Exomiser and GADO without requiring changes to core workflow logic.

#### tool_config_template.yml (required)

A YAML template describing the tool’s configuration fields. 

Example minimal structure:

```yaml
tool: TOOLNAME
tool_version: {{VERSION}}
gene_analysis: True
variant_analysis: False
disease_analysis: False
tool_specific_configuration_options:
  param_a: {{PARAM_A}}
  param_b: {{PARAM_B}}
```

Anything inside {{ … }} will be substituted using values from `params.tools` section in the `nextflow.config`.

#### containers/pheval-TOOL.def (optional)

A Singularity .def file defining how to build the runtime container.
Only needed if the tool cannot run inside an existing shared environment.

#### envs/pheval-TOOL.yml (optional)

Conda environment file for users who aren’t using Singularity.

### 2. Updating nextflow.config (required)

Every new tool must add an entry to the `params.tools` list in the `nextflow.config`:
```
params.tools = [
    [
      config_id       : "toolname-1.0",
      tool            : "toolname",
      runner          : "toolnamephevalrunner",
      version         : "1.0",
      config_template : "${projectDir}/modules/tools/toolname/tool_config_template.yml",

      // Add any additional fields needed by toolPrepareConfigurations.nf:
      param_a: "...",
      param_b: "...",
    ],
]
```

Required fields:

| Field            | Description                                           |
|------------------|-------------------------------------------------------|
| `config_id`      | Output directory name and configuration label         |
| `tool`           | Name used to filter tool configs in `main.nf`         |
| `version`        | Tool version passed into the configuration and runner |
| `config_template`| Path to the tool’s YAML configuration template        |

Optional fields:

Any custom fields required by your tool go here. They will be available inside both:

* `toolPrepareConfigurations.nf`
* `toolRunner.nf`

### 3. Updating the HPC / Local Configs (required)

Each tool must specify runtime and container requirements:

```groovy
process {

    withName:runTOOLNAMERunner {
        container = "sif/pheval-TOOLNAME.sif"
        clusterOptions = "-cwd -j y -pe smp 4 -l h_vmem=4G -l h_rt=12:00:00"
    }

    withName:prepareTOOLNAMEConfigurations {
        container = ""  // Typically runs locally without a container
        clusterOptions = "-cwd -j y -pe smp 1 -l h_vmem=2G -l h_rt=01:00:00"
    }
}
```
This ensures the tool uses the correct runtime environment.

### 4. Updating main.nf (required)

Every new tool must be explicitly included at the top of `main.nf`:

```
include { prepareTOOLNAMEConfigurations } from './modules/tools/toolname/toolPrepareConfigurations.nf'
include { runTOOLNAMERunner           }  from './modules/tools/toolname/toolRunner.nf'
```

Then inside the workflow:

```

workflow {

    tool_cfg_ch = configs_ch.filter { it.tool == 'toolname' }

    tool_prepared = prepareTOOLNAMEConfigurations(tool_cfg_ch)

    tool_runner_out = runTOOLNAMERunner(
        tool_prepared.cfg.combine(corpora_ch.corpus)
    )

    all_runners_out = all_runners_out.concat(tool_runner_out.run)
}

```

The pipeline will automatically:

* Create configs 
* Run the tool for each corpus 
* Pass results to benchmarking

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
* configurations/ – Prepared tool configuration directories 
* corpora/ – Staging area for phenopackets and VCFs 
* results/ – Results of all runs (raw and PhEval-standardised)
* benchmark/ – Benchmark results, including plots, summary statistics, and evaluation metrics

Benchmarks are corpus-specific: for each corpus, a YAML configuration file and corresponding plots/statistics are created.


