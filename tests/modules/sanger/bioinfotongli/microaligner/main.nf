#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { BIOINFOTONGLI_MICROALIGNER } from '../../../../../modules/sanger/bioinfotongli/microaligner/main.nf'

workflow test_bioinfotongli_microaligner {
    
    input = [
        [ id:'test', single_end:false ], // meta map
        file(params.test_data['sarscov2']['illumina']['test_paired_end_bam'], checkIfExists: true)
    ]

    BIOINFOTONGLI_MICROALIGNER ( input )
}
