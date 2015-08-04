targets = [

    'tools/data_qa.html',
    '/data/datasets/filtered/rnaseq_expression/HMCL_ensembl74_Counts_zscore.csv',
    '/data/datasets/filtered/rnaseq_expression/HMCL_ensembl74_Counts_zscore_estimates.csv',
    '/data/datasets/raw/gene_ontology/ensembl_go_mapping.tab',
]
import os
from textwrap import dedent


def compile_Rmd(fn):
    with open(os.path.basename(fn) + '.driver', 'w') as fout:
        fout.write(dedent(
            """
            library(knitr)
            library(rmarkdown)
            render("{0}", output_format="all", clean=TRUE)
            """.format(fn)))
    shell("/usr/bin/Rscript {0}".format(fout.name))
    shell("rm {0}".format(fout.name))


def run_R(fn):
    shell("/usr/bin/Rscript {fn}")


rule all:
    input: targets


rule rmd:
    input: '{prefix}.Rmd'
    output: '{prefix}.html'
    run:
        compile_Rmd(input[0])


rule compute_zscores:
    input: "tools/rnaseq_data_zscore_calculation.R"
    output: 
        '/data/datasets/filtered/rnaseq_expression/HMCL_ensembl74_Counts_zscore.csv',
        '/data/datasets/filtered/rnaseq_expression/HMCL_ensembl74_Counts_zscore_estimates.csv'
    run:
        run_R(input[0])


rule download_go:
    input: 'tools/generate_ensembl_go_mapping.R'
    output: '/data/datasets/raw/gene_ontology/ensembl_go_mapping.tab'
    run:
        run_R(input[0])
