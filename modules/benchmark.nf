#!/usr/bin/env nextflow

process createBenchmarkConfig {
    publishDir "${params.benchmark_dir}", mode: 'copy', overwrite: true

    input:
    tuple val(corpus_id), val(cfgs)

    output:
    path "${corpus_id}_*"

    script:
    """
    out_yaml=${corpus_id}_benchmark.yaml

    # Extract flags safely from config_template
    gene_analysis=\$(grep '^gene_analysis:' ${params.config_template} | awk '{print tolower(\$2)}')
    variant_analysis=\$(grep '^variant_analysis:' ${params.config_template} | awk '{print tolower(\$2)}')
    disease_analysis=\$(grep '^disease_analysis:' ${params.config_template} | awk '{print tolower(\$2)}')

    echo "benchmark_name: ${corpus_id}_exomiser_benchmark" > \$out_yaml
    echo "runs:" >> \$out_yaml

    for cfg in ${cfgs}; do
        run_id=\$(echo \$cfg | tr '/' '_')
        results_dir="${params.results_dir}/\$cfg/${corpus_id}"
        phenopacket_dir="${params.corpora_dir}/${corpus_id}/phenopackets"

        cat >> \$out_yaml <<EOF
  - run_identifier: \$run_id
    results_dir: \$results_dir
    phenopacket_dir: \$phenopacket_dir
    gene_analysis: \$gene_analysis
    variant_analysis: \$variant_analysis
    disease_analysis: \$disease_analysis
    threshold:
    score_order: descending
EOF
    done

    cat >> \$out_yaml <<EOF
plot_customisation:
  gene_plots:
    plot_type: bar_cumulative
    rank_plot_title:
    roc_curve_title:
    precision_recall_title:
  disease_plots:
    plot_type: bar_cumulative
    rank_plot_title:
    roc_curve_title:
    precision_recall_title:
  variant_plots:
    plot_type: bar_cumulative
    rank_plot_title:
    roc_curve_title:
    precision_recall_title:
EOF
    pheval-utils benchmark -r \$out_yaml
    """
}