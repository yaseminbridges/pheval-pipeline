#!/usr/bin/env nextflow

process createBenchmarkConfig {
    publishDir "${params.benchmark_dir}", mode: 'copy', overwrite: true

    input:
    tuple val(corpus_id), path("runs_info.txt")

    output:
    path "benchmark_${corpus_id}.yml"

    script:
    """
    gene_analysis=\$(yq e '.gene_analysis' ${params.config_template})
    variant_analysis=\$(yq e '.variant_analysis' ${params.config_template})
    disease_analysis=\$(yq e '.disease_analysis' ${params.config_template})

    echo "benchmark_name: ${corpus_id}_benchmark" > benchmark_${corpus_id}.yml
    echo "runs:" >> benchmark_${corpus_id}.yml

    while read run_id results_dir; do
      cat >> benchmark_${corpus_id}.yml <<EOF
  - run_identifier: \${run_id}
    results_dir: \${results_dir}
    phenopacket_dir:
    gene_analysis: \${gene_analysis}
    variant_analysis: \${variant_analysis}
    disease_analysis: \${disease_analysis}
    threshold:
    score_order: descending
EOF
    done < runs_info.txt

    cat >> benchmark_${corpus_id}.yml <<EOF
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
    """
}