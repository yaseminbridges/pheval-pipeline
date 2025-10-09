nextflow.enable.dsl=2

workflow {
    pheval_exomiser()
}

process pheval_exomiser {

publishDir "results/exomiser", mode: 'copy'

    conda = "envs/pheval-exomiser.yml"

    script:
    """
    pheval-exomiser --help
    """
}