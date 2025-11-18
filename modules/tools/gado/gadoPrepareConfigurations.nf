#!/usr/bin/env nextflow

process prepareGADOConfigurations {
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

    fetch() {
        src="\$1"
        if echo "\$src" | grep -qE '^https?://'; then
            fname=\$(basename "\$src")
            wget -q "\$src" -O "\$fname"
        else
            fname=\$(basename "\$src")
            ln -s "\$src" "\$fname"
        fi
        echo "\$fname"
    }

    gado_tar=\$(fetch "${cfg.gado_command_line}")
    tar -zxf "\$gado_tar"
    gado_dir=\$(find . -maxdepth 1 -type d -name "GadoCommandline*" | head -n 1)
    gado_jar="\$gado_dir/GADO.jar"

    matrix_file=\$(fetch "${cfg.prediction_matrix}")
    if [[ "\$matrix_file" == *.zip ]]; then
        unzip -oq "\$matrix_file"
        matrix_dir=\$(find . -maxdepth 1 -type d -name "*bonf*spiked*" | head -n 1)
        prediction_matrix="\$matrix_dir/genenetwork_bonf_spiked.dat"
    else
        prediction_matrix="\$matrix_file"
    fi

    prediction_info=\$(fetch "${cfg.prediction_info}")
    genes_file=\$(fetch "${cfg.genes}")
    ontology_file=\$(fetch "${cfg.hpo_ontology}")

    sed \
      -e "s|{{GADO_VERSION}}|${cfg.gado_version}|g" \
      -e "s|{{GADO_JAR}}|\$gado_jar|g" \
      -e "s|{{HPO_ONTOLOGY}}|\$ontology_file|g" \
      -e "s|{{PREDICTION_INFO}}|\$prediction_info|g" \
      -e "s|{{GENES}}|\$genes_file|g" \
      -e "s|{{PREDICTION_MATRIX}}|\$prediction_matrix|g" \
      ${params.gado_config_template} > config.yaml
    """
}