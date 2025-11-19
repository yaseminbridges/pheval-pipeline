#!/usr/bin/env nextflow

include { prepareExomiserConfigurations } from './modules/tools/exomiser/exomiserPrepareConfigurations.nf'
include { prepareGADOConfigurations } from './modules/tools/gado/gadoPrepareConfigurations.nf'

include { prepareCorpora } from './modules/prepareCorpora.nf'
include { runExomiserRunner } from './modules/tools/exomiser/exomiserRunner.nf'
include { runGADORunner } from './modules/tools/gado/gadoRunner.nf'
include { benchmark } from './modules/benchmark.nf'

workflow {
    corpora_ch = prepareCorpora(Channel.fromList(params.corpora_configs))

    configs_ch = Channel.fromList(params.tools)

    exomiser_cfg_ch = configs_ch.filter { it.tool == 'exomiser' }

    gado_cfg_ch     = configs_ch.filter { it.tool == 'gado' }

    exomiser_prepared = prepareExomiserConfigurations(exomiser_cfg_ch)

    gado_prepared     = prepareGADOConfigurations(gado_cfg_ch)

    exomiser_runner_out = runExomiserRunner(exomiser_prepared.cfg.combine(corpora_ch.corpus))

    gado_runner_out = runGADORunner(gado_prepared.cfg.combine(corpora_ch.corpus))

    all_runners_out = exomiser_runner_out.run.concat(gado_runner_out.run)

    grouped = all_runners_out.groupTuple(by: 0)

    grouped = grouped.map { corpus_id, cfgs -> tuple(corpus_id, cfgs.join(" ")) }

    benchmark(grouped)
}