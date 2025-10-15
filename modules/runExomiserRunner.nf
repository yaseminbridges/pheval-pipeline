#!/usr/bin/env nextflow

process runExomiserRunner {
    publishDir "${params.results_dir}", mode: 'copy', overwrite: true

    input:
    tuple val(cfg), val(corpus)

    script:
    """
    mkdir -p ${params.results_dir}/${cfg.config_id}/${corpus.corpora_id}
    pheval run \
      -i ${params.configurations_dir}/${cfg.config_id} \
      -r exomiserphevalrunner \
      -t ${params.corpora_dir}/${corpus.corpora_id} \
      -o ${params.results_dir}/${cfg.config_id}/${corpus.corpora_id} \
      -v ${cfg.exomiser_version}
    """
}