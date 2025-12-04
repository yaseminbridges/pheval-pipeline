#!/usr/bin/env nextflow

include { prepareCorpora } from './modules/prepareCorpora.nf'
include { benchmark } from './modules/benchmark.nf'

include { prepareExomiserConfigurations } from './modules/tools/exomiser/exomiserPrepareConfigurations.nf'
include { runExomiserRunner } from './modules/tools/exomiser/exomiserRunner.nf'

include { prepareGADOConfigurations } from './modules/tools/gado/gadoPrepareConfigurations.nf'
include { runGADORunner } from './modules/tools/gado/gadoRunner.nf'

workflow {
    // Corpora workflow
    // Users should NOT modify this
    // Builds all phenopackets/VCF corpora the pipeline will run tools on
    corpora_ch = prepareCorpora(Channel.fromList(params.corpora_configs))

    // Tool configuration workflow
    // Users should NOT modify the Channel.fromList(params.tools)
    configs_ch = Channel.fromList(params.tools)

    // Exomiser workflow
    exomiser_cfg_ch = configs_ch.filter { it.tool == 'exomiser' }
    exomiser_prepared = prepareExomiserConfigurations(exomiser_cfg_ch)
    exomiser_runner_out = runExomiserRunner(exomiser_prepared.cfg.combine(corpora_ch.corpus))

    // GADO workflow
    gado_cfg_ch = configs_ch.filter { it.tool == 'gado' }
    gado_prepared = prepareGADOConfigurations(gado_cfg_ch)
    gado_runner_out = runGADORunner(gado_prepared.cfg.combine(corpora_ch.corpus))

    // Combine outputs of ALL tool all_runners
    // Users MUST append their new runner's output here using `.concat()`
    all_runners_out = exomiser_runner_out.run.concat(gado_runner_out.run)

    // Benchmark workflow
    // Users should NOT change anything below this point
    grouped = all_runners_out.groupTuple(by: 0)
    grouped = grouped.map { corpus_id, cfgs -> tuple(corpus_id, cfgs.join(" ")) }
    benchmark(grouped)
}