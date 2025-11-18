#!/usr/bin/env nextflow

process prepareExomiserConfigurations {
    publishDir "${params.configurations_dir}", mode: 'move', overwrite: true, followLinks: true

    input:
    val cfg

    output:
    val(cfg), emit: cfg
    path("${cfg.config_id}", type: 'dir')

    script:
    """
    mkdir -p ${cfg.config_id}
    cd ${cfg.config_id}

    ln -s ${params.exomiser_data_dir}/${cfg.phenotype_db}_phenotype ./
    if [ -n "${cfg.hg19_db}" ]; then
        ln -s ${params.exomiser_data_dir}/${cfg.hg19_db}_hg19 ./
    fi
    if [ -n "${cfg.hg38_db}" ]; then
        ln -s ${params.exomiser_data_dir}/${cfg.hg38_db}_hg38 ./
    fi

    cp -r ${params.exomiser_distribution_dir}/exomiser-cli-${cfg.exomiser_version} ./

    cp ${baseDir}/presets/${cfg.preset} ./

    sed -e "s|{{EXOMISER_VERSION}}|${cfg.exomiser_version}|g" \
        -e "s|{{HG19_VERSION}}|\"${cfg.hg19_db}\"|g" \
        -e "s|{{HG38_VERSION}}|\"${cfg.hg38_db}\"|g" \
        -e "s|{{PHENO_VERSION}}|\"${cfg.phenotype_db}\"|g" \
        -e "s|{{PRESET}}|${cfg.preset}|g" \
        ${params.exomiser_config_template} > config.yaml
    """
}