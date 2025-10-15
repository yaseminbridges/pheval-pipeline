#!/usr/bin/env nextflow

// nextflow.enable.dsl=2

params.configurations_dir = "${projectDir}/configurations"
params.corpora_dir        = "${projectDir}/corpora"
params.results_dir        = "${projectDir}/results"

// process prepare_exomiser_input {
//     publishDir "configurations", mode: 'move', overwrite: true, followLinks: true
//
//     input:
//     val cfg
//
//     output:
//     tuple val(cfg), path("${cfg.config_id}", type: 'dir')
//
//     script:
//     """
//     mkdir -p ${cfg.config_id}
//     cd ${cfg.config_id}
//
//     ln -s ${params.data_dir}/${cfg.phenotype_db}_phenotype ./
//     if [ -n "${cfg.hg19_db}" ]; then
//         ln -s ${params.data_dir}/${cfg.hg19_db}_hg19 ./
//     fi
//     if [ -n "${cfg.hg38_db}" ]; then
//         ln -s ${params.data_dir}/${cfg.hg38_db}_hg38 ./
//     fi
//
//     cp -r ${params.exomiser_distribution_dir}/exomiser-cli-${cfg.exomiser_version} ./
//
//     cp ${baseDir}/presets/${cfg.preset} ./
//
//     sed -e "s|{{EXOMISER_VERSION}}|${cfg.exomiser_version}|g" \
//         -e "s|{{HG19_VERSION}}|\"${cfg.hg19_db}\"|g" \
//         -e "s|{{HG38_VERSION}}|\"${cfg.hg38_db}\"|g" \
//         -e "s|{{PHENO_VERSION}}|\"${cfg.phenotype_db}\"|g" \
//         -e "s|{{PRESET}}|${cfg.preset}|g" \
//         ${params.config_template} > config.yaml
//     """
// }
//
// process prepare_corpora {
//     publishDir "corpora", mode: 'move', overwrite: true, followLinks: true
//
//     input:
//     val corpus
//
//     output:
//     tuple val(corpus), path("${corpus.corpora_id}", type: 'dir')
//
//     script:
//     """
//     mkdir -p ${corpus.corpora_id}
//
//     ln -s ${corpus.phenopacket_directory} ${corpus.corpora_id}/phenopackets
//     if [ -n "${corpus.vcf_directory}" ]; then
//         ln -s ${corpus.vcf_directory} ${corpus.corpora_id}/vcf
//     fi
//     """
// }
//
// process run_pheval {
//     publishDir "${params.results_dir}", mode: 'copy', overwrite: true
//
//     input:
//     tuple val(cfg), path(config_dir), val(corpus), path(corpus_dir)
//
//     script:
//     """
//     mkdir -p ${params.results_dir}/${cfg.config_id}/${corpus.corpora_id}
//     pheval run \
//       -i ${params.configurations_dir}/${cfg.config_id} \
//       -r exomiserphevalrunner \
//       -t ${params.corpora_dir}/${corpus.corpora_id} \
//       -o ${params.results_dir}/${cfg.config_id}/${corpus.corpora_id} \
//       -v ${cfg.exomiser_version}
//     """
// }


include { prepareExomiserConfigurations } from './modules/prepareExomiserConfigurations.nf'
include { prepareCorpora } from './modules/prepareExomiserConfigurations.nf'
include { runExomiserRunner } from './modules/runExomiserRunner.nf'

workflow {
    exo_ch     = Channel.fromList(params.exomiser_configs) | prepareExomiserConfigurations
    corpora_ch = Channel.fromList(params.corpora_configs)  | prepareCorpora

    exo_ch.combine(corpora_ch) | runExomiserRunner
}