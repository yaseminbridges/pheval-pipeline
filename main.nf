#!/usr/bin/env nextflow

params.configurations_dir = "${projectDir}/configurations"
params.corpora_dir        = "${projectDir}/corpora"
params.results_dir        = "${projectDir}/results"

include { prepareExomiserConfigurations } from './modules/prepareExomiserConfigurations.nf'
include { prepareCorpora } from './modules/prepareCorpora.nf'
include { runExomiserRunner } from './modules/runExomiserRunner.nf'

workflow {
    exomiser_configurations_ch = prepareExomiserConfigurations(Channel.fromList(params.exomiser_configs))
    corpora_ch = prepareCorpora(Channel.fromList(params.corpora_configs))

    runExomiserRunner(exomiser_configurations_ch.combine(corpora_ch))
}