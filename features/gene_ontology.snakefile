import pandas as pd

rule download_go:
    output: '{prefix}/raw/gene_ontology/ensembl_go_mapping.tab'
    shell:
        """
        {programs.Rscript.prelude}
        {programs.Rscript.path} tools/generate_ensembl_go_mapping.R {output}
        """

rule go_term_zscores:
    input:
        zscores=config['features']['zscores']['output']['zscores'],
        go_mapping=rules.download_go.output
    output: config['features']['go']['output']['zscores']
    run:
        dfs = pipeline_helpers.pathway_scores_from_zscores(
            pd.read_table(str(input.zscores), index_col=0),
            pd.read_table(str(input.go_mapping), index_col=0)[['GO']],
            'GO'
        )

        dfs.to_csv(output[0], sep='\t', index_label='pathway_id')


rule go_term_variant_scores:
    input:
        variants=config['features']['exome_variants']['output']['by_gene'],
        go_mapping=rules.download_go.output
    output: config['features']['go']['output']['variants']
    run:
        dfs = pipeline_helpers.pathway_scores_from_variants(
            pd.read_table(str(input.variants), index_col=0),
            pd.read_table(str(input.go_mapping), index_col=0)[['GO']],
            'GO'
        )
        dfs.to_csv(output[0], sep='\t', index_label='pathway_id')

# vim: ft=python
