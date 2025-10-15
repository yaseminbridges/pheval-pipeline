#!/usr/bin/env nextflow

params.configurations_dir = "${projectDir}/configurations"
params.corpora_dir        = "${projectDir}/corpora"
params.results_dir        = "${projectDir}/results"

include { prepareExomiserConfigurations } from './modules/prepareExomiserConfigurations.nf'
include { prepareCorpora } from './modules/prepareCorpora.nf'
include { runExomiserRunner } from './modules/runExomiserRunner.nf'

workflow {
    exo_ch     = Channel.fromList(params.exomiser_configs) | prepareExomiserConfigurations
    corpora_ch = Channel.fromList(params.corpora_configs)  | prepareCorpora

    exo_ch.combine(corpora_ch) | runExomiserRunner
}