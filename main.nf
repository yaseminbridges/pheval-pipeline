nextflow.enable.dsl=2

workflow {
    Channel.fromList(params.exomiser_configs)
        | prepare_exomiser_inputs
        | pheval_exomiser
}

process prepare_exomiser_input {
    publishDir "configurations", mode: 'copy'

    input:
    val cfg

    output:
    path "." into exomiser_dirs

    script:
    """
    mkdir -p exomiser-${cfg.exomiser_version}/${cfg.phenotype_db}_pheno_${cfg.hg19_db}_hg19_${cfg.hg38_db}_hg38/${cfg.preset%.*}
    cd exomiser-${cfg.exomiser_version}/${cfg.phenotype_db}_pheno_${cfg.hg19_db}_hg19_${cfg.hg38_db}_hg38/${cfg.preset%.*}

    # Symlink Exomiser software + DBs
    ln -s ${params.data_dir}/exomiser-${cfg.exomiser_version}/exomiser-cli-${cfg.exomiser_version} ./
    ln -s ${params.data_dir}/exomiser-${cfg.exomiser_version}/${cfg.phenotype_db}_phenotype ./
    ln -s ${params.data_dir}/exomiser-${cfg.exomiser_version}/${cfg.hg19_db}_hg19 ./
    ln -s ${params.data_dir}/exomiser-${cfg.exomiser_version}/${cfg.hg38_db}_hg38 ./

    # Copy preset into place (standardised name for Exomiser)
    cp configs/${cfg.preset} ./preset-exome-analysis.yml

    # Generate config.yaml using the chosen preset
    sed -e "s|EXOMISER_VERSION|${cfg.exomiser_version}|g" \\
        -e "s|PHENO_DB_VERSION|${cfg.phenotype_db}|g" \\
        -e "s|HG19_DB_VERSION|${cfg.hg19_db}|g" \\
        -e "s|HG38_DB_VERSION|${cfg.hg38_db}|g" \\
        -e "s|PRESET_FILE|preset-exome-analysis.yml|g" \\
        ${params.config_template} > config.yaml
    """
}

process pheval_exomiser {
    publishDir "results/exomiser", mode: 'copy'

    input:
    path input_dir

    script:
    """
    pheval-exomiser --input $input_dir
    """
}