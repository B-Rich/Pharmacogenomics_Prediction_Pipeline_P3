import yaml
from tools import pipeline_helpers
import os
import pandas
from textwrap import dedent

localrules: make_lookups


config = yaml.load(open('config.yaml'))
samples = [i.strip() for i in open(config['samples'])]
config['sample_list'] = samples
feature_targets = []
for name in config['features_to_use']:
    cfg = config['features'][name]
    workflow.include(cfg['snakefile'])
    outputs = cfg['output']
    if isinstance(outputs, dict):
        outputs = outputs.values()
    elif not isinstance(outputs, list):
        outputs = [outputs]
    for output in outputs:
        feature_targets.append(output.format(prefix=config['prefix']))

Rscript = config['Rscript']

lookup_targets = [i.format(prefix=config['prefix']) for i in [
    '{prefix}/metadata/ENSG2ENTREZID.tab',
    '{prefix}/metadata/ENSG2SYMBOL.tab',
    '{prefix}/metadata/genes.bed',
]]

rule all_features:
    input: feature_targets + lookup_targets


rule make_lookups:
    output: '{prefix}/metadata/ENSG2{map}.tab'
    shell:
        """
        {Rscript} tools/make_lookups.R {wildcards.map} {output}
        """

rule make_genes:
    output: '{prefix}/metadata/genes.bed'
    shell:
        """
        {Rscript} tools/make_gene_lookup.R {output}
        sed -i "s/^chr//g" {output}
        """

# For each configured sample, converts the NCATS-format input file into several
# processed files.
rule process_response:
    input: '{prefix}/raw/drug_response/s-tum-{sample}-x1-1.csv'
    output:
        drugIds_file='{prefix}/processed/drug_response/{sample}_drugIds.tab',
        drugResponse_file='{prefix}/processed/drug_response/{sample}_drugResponse.tab',
        drugDoses_file='{prefix}/processed/drug_response/{sample}_drugDoses.tab',
        drugDrc_file='{prefix}/processed/drug_response/{sample}_drugDrc.tab'
    params: uniqueID='SID'
    shell:
        """
        {Rscript} tools/drug_response_process.R {input} \
        {output.drugIds_file} {output.drugResponse_file} {output.drugDoses_file} \
        {output.drugDrc_file} {params.uniqueID}
        """
# Create a fresh copy of example_data
# Used for testing the pipeline starting from raw data.
rule prepare_example_data:
    shell:
        """
        if [ -e example_data ]; then
            rm -rf example_data
        fi
        mkdir -p example_data
        (cd example_data && unzip ../sample_in_progress/raw.zip)
        """

# vim: ft=python
