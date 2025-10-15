#!/usr/bin/env nextflow

process prepareCorpora {
    publishDir "${params.corpora_dir}", mode: 'move', overwrite: true, followLinks: true

    input:
    val corpus

    output:
    val(corpus)

    script:
    """
    mkdir -p ${corpus.corpora_id}

    ln -s ${corpus.phenopacket_directory} ${corpus.corpora_id}/phenopackets
    if [ -n "${corpus.vcf_directory}" ]; then
        ln -s ${corpus.vcf_directory} ${corpus.corpora_id}/vcf
    fi
    """
}