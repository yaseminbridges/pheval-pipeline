nextflow.enable.dsl=2

workflow {
    pheval_exomiser()
}

process pheval_exomiser {
    publishDir "results/exomiser", mode: 'copy'

    script:
    """
    pheval-exomiser --help
    """
}
