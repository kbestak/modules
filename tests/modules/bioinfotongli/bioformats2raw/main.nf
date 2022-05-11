#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { BIOINFOTONGLI_BIOFORMATS2RAW } from '../../../../modules/bioinfotongli/bioformats2raw/main.nf'

workflow test_bioinfotongli_bioformats2raw {
    
    input = file(params.test_data['sarscov2']['illumina']['test_single_end_bam'], checkIfExists: true)

    BIOINFOTONGLI_BIOFORMATS2RAW ( input )
}
