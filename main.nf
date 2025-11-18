#!/usr/bin/env nextflow

include { prepareExomiserConfigurations } from './modules/tools/exomiser/exomiserPrepareConfigurations.nf'
include { prepareGADOConfigurations } from './modules/tools/exomiser/gadoPrepareConfigurations.nf'

include { prepareCorpora } from './modules/prepareCorpora.nf'
include { runExomiserRunner } from './modules/tools/exomiser/exomiserRunner.nf'
include { benchmark } from './modules/benchmark.nf'
include { runToolRunner } from './modules/runTool.nf'

workflow {
    corpora_ch = prepareCorpora(Channel.fromList(params.corpora_configs))

    configs_ch = Channel.fromList(params.tools)

    prepared_configs = configs_ch.flatMap { cfg ->
        switch(cfg.tool) {
            case 'exomiser':
                return prepareExomiserConfigurations(Channel.of(cfg))
            case 'gado':
                return prepareGADOConfigurations(Channel.of(cfg))
            default:
                throw new IllegalArgumentException("Unknown tool: ${cfg.tool}")
        }
    }

    runner_out = runTool(prepared_configs.cfg.combine(corpora_ch.corpus))

    grouped = runner_out.run.groupTuple(by: 0)

    grouped = grouped.map { corpus_id, cfgs -> tuple(corpus_id, cfgs.join(" ")) }

    benchmark(grouped)
}