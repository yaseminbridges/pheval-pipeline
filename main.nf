#!/usr/bin/env nextflow

params.configurations_dir = "${projectDir}/configurations"
params.corpora_dir        = "${projectDir}/corpora"
params.results_dir        = "${projectDir}/results"
params.benchmark_dir        = "${projectDir}/benchmark"

include { prepareExomiserConfigurations } from './modules/prepareExomiserConfigurations.nf'
include { prepareCorpora } from './modules/prepareCorpora.nf'
include { runExomiserRunner } from './modules/runExomiserRunner.nf'

workflow {
    exomiser_configurations_ch = prepareExomiserConfigurations(Channel.fromList(params.exomiser_configs))
    corpora_ch = prepareCorpora(Channel.fromList(params.corpora_configs))

    runExomiserRunner(exomiser_configurations_ch.combine(corpora_ch))

    grouped = runs_ch
        .map { corpus_id, config_id, results_path ->
            run_id = config_id.replaceAll('/', '_')
            tuple(corpus_id, run_id, results_path)
        }
        .groupTuple()

    grouped.map { corpus_id, runs ->
        def runs_info = file("runs_info.txt")
        runs_info.text = runs.collect { run_id, results_path ->
            "${run_id} ${results_path}"
        }.join('\n')
        tuple(corpus_id, runs_info)
    } | createBenchmarkConfig
}