nextflow.enable.dsl=2

process prepare_exomiser_input {
    publishDir "configurations", mode: 'move', overwrite: true, followLinks: false

    input:
    val cfg

    output:
    path "${cfg.config_id}"

    script:
    """
    # Make config-specific directory
    mkdir -p ${cfg.config_id}
    cd ${cfg.config_id}

    # Symlink databases
    ln -s ${params.data_dir}/${cfg.phenotype_db}_phenotype ./
    ln -s ${params.data_dir}/${cfg.hg19_db}_hg19 ./
    ln -s ${params.data_dir}/${cfg.hg38_db}_hg38 ./

    sed -e "s|{{EXOMISER_VERSION}}|${cfg.exomiser_version}|g" \
    -e "s|{{HG19_VERSION}}|${cfg.hg19_db}|g" \
    -e "s|{{HG38_VERSION}}|${cfg.hg38_db:-}|g" \
    -e "s|{{PHENO_VERSION}}|${cfg.phenotype_db}|g" \
    -e "s|{{PRESET}}|${cfg.preset}|g" \
    ${params.config_template} > config.yaml



    # Copy preset into place under standardised name
    #cp configs/${cfg.preset} ./preset-exome-analysis.yml

    # Drop a dummy config file for now
    #echo "Pretend config for ${cfg}" > config.yaml
    """
}

//
// process pheval_exomiser {
//     publishDir "results/exomiser", mode: 'copy'
//
//     input:
//     path input_dir
//
//     script:
//     """
//     pheval-exomiser --input $input_dir --help
//     """
// }
//

workflow {
    Channel.fromList(params.exomiser_configs) \
        | prepare_exomiser_input
        // | pheval_exomiser
}
