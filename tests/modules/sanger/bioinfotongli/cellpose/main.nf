#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { BIOINFOTONGLI_CELLPOSE } from '../../../../../modules/sanger/bioinfotongli/cellpose/main.nf'

workflow test_bioinfotongli_cellpose {
    
    input = [
        [ id:'test', single_end:false ], // meta map
        file(params.test_data['sarscov2']['illumina']['test_paired_end_bam'], checkIfExists: true)
    ]

    BIOINFOTONGLI_CELLPOSE ( input )
}
