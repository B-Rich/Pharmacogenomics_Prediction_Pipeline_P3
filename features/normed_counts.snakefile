# vim: ft=python
import pandas
import os


rule rnaseq_counts_matrix:
    input: expand('{{prefix}}/raw/rnaseq_expression/{sample}_counts.tsv', sample=samples)
    output: '{prefix}/raw/rnaseq_expression/counts_matrix.tsv'
    run:
        df = pipeline_helpers.stitch(
            input,
            lambda x: os.path.basename(x).replace('_counts.tsv', ''),
            index_col=0,
            sep='\t'
        )
        df.to_csv(output[0], sep='\t')

rule rnaseq_visualization_raw:
    input: '{prefix}/raw/rnaseq_expression/counts_matrix.tsv'
    output: '{prefix}/reports/raw_rnaseq.html'
    shell:
        """
        {programs.Rscript.prelude}
        {programs.Rscript.path} tools/visualize_rnaseq_data.R {input} {output} 'RNA-Seq' 'Raw'
        """

rule rnaseq_visualization_normed:
    input: 
        config['features']['normed_counts']['output']['normed_counts']
    output: '{prefix}/reports/normalized_rnaseq.html'
    shell:
        """
        {programs.Rscript.prelude}
        {programs.Rscript.path} tools/visualize_rnaseq_data.R {input} {output} 'RNA-Seq' 'Normalized'
        """

rule rnaseq_data_prep:
    input:
        "{prefix}/raw/rnaseq_expression/counts_matrix.tsv"
    output:
        config['features']['normed_counts']['output']['normed_counts']
    shell:
        """
        {programs.Rscript.prelude}
        {programs.Rscript.path} tools/rnaseq_data_preparation.R {input} {output}
        """

