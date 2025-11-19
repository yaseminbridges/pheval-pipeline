#!/usr/bin/env nextflow

process runExomiserRunner {
    publishDir "${params.results_dir}", mode: 'copy', overwrite: true

    input:
    tuple val(cfg), val(corpus)

    output:
    tuple val(corpus.corpora_id), val(cfg.config_id), emit: run

    path("${cfg.config_id}/${corpus.corpora_id}", type: 'dir')


    script:
    """

    outdir="\$PWD/${cfg.config_id}/${corpus.corpora_id}"
    mkdir -p "\$outdir"

    pheval run \
      -i ${params.configurations_dir}/${cfg.config_id} \
      -r exomiserphevalrunner \
      -t ${params.corpora_dir}/${corpus.corpora_id} \
      -o "\$outdir" \
      -v ${cfg.version}
    """
}