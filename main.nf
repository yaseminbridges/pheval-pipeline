#!/usr/bin/env nextflow

params.configurations_dir = "${projectDir}/configurations"
params.corpora_dir        = "${projectDir}/corpora"
params.results_dir        = "${projectDir}/results"
params.benchmark_dir        = "${projectDir}/benchmark"

include { prepareExomiserConfigurations } from './modules/prepareExomiserConfigurations.nf'
include { prepareCorpora } from './modules/prepareCorpora.nf'
include { runExomiserRunner } from './modules/runExomiserRunner.nf'
include { createBenchmarkConfig } from './modules/benchmark.nf'

workflow {
    exomiser_configurations_ch = prepareExomiserConfigurations(Channel.fromList(params.exomiser_configs))
    corpora_ch = prepareCorpora(Channel.fromList(params.corpora_configs))

    runner_out = runExomiserRunner(exomiser_configurations_ch.combine(corpora_ch))

    grouped = runner_out.groupTuple(by: 0)

    grouped = grouped.map { corpus_id, cfgs -> tuple(corpus_id, cfgs.join(" ")) }

    createBenchmarkConfig(grouped)
}