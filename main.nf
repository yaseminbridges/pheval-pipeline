#!/usr/bin/env nextflow

include { prepareExomiserConfigurations } from './modules/tools/exomiser/exomiserPrepareConfigurations.nf'
include { prepareCorpora } from './modules/prepareCorpora.nf'
include { runExomiserRunner } from './modules/tools/exomiser/exomiserRunner.nf'
include { benchmark } from './modules/benchmark.nf'

workflow {
    exomiser_configurations_ch = prepareExomiserConfigurations(Channel.fromList(params.exomiser_configs))
    corpora_ch = prepareCorpora(Channel.fromList(params.corpora_configs))

    runner_out = runExomiserRunner(exomiser_configurations_ch.cfg.combine(corpora_ch.corpus))

    grouped = runner_out.run.groupTuple(by: 0)

    grouped = grouped.map { corpus_id, cfgs -> tuple(corpus_id, cfgs.join(" ")) }

    benchmark(grouped)
}