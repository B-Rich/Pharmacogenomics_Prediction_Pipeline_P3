import pandas
import numpy


rule transcript_variant_matrix:
    input: expand('{{prefix}}/raw/exome_variants/{sample}_exome_variants.txt', sample=samples)
    output: '{prefix}/cleaned/exome_variants/exome_variants_by_transcript.tab'
    run:
        dfs = []
        for fn in input:
            df = pandas.read_table(fn)
            df['sample'] = '_'.join(os.path.basename(fn).split('_')[:2])
            dfs.append(df)
        dfs = pandas.concat(dfs)
        dfs.index = numpy.arange(len(dfs))
        results = pandas.pivot_table(
            dfs[['EFF[*].TRID', 'sample']],
            columns='sample',
            index='EFF[*].TRID',
            aggfunc=len)\
                .dropna(how='all')\
                .fillna(0)
        results.to_csv(output[0], sep='\t')


rule transcript_variant_matrix_to_gene_variant_matrix:
    input:
        variants_table='{prefix}/cleaned/exome_variants/exome_variants_by_transcript.tab',
        lookup_table='{prefix}/metadata/ENSG2ENSEMBLTRANS.tab'
    output: config['features']['exome_variants']['output']['by_gene']
    run:
        lookup = pandas.read_table(str(input.lookup_table), index_col='ENSEMBLTRANS')
        variants = pandas.read_table(str(input.variants_table), index_col='EFF[*].TRID')
        x = variants.join(lookup).dropna(subset=['ENSEMBL'])
        results = x.groupby('ENSEMBL').agg(numpy.sum)
        results.to_csv(output[0], sep='\t')

rule gene_snp_visualization:
    input: 
        config['features']['exome_variants']['output']['by_gene']
    output: '{prefix}/reports/cleaned_snps.html'
    shell:
        """
        {programs.Rscript.prelude}
        {programs.Rscript.path} tools/visualize_exome_data.R {input} {output} 'SNPs' 'Cleaned'
        """

# vim: ft=python
