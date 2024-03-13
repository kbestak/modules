include { BIOINFOTONGLI_BASICFITTING      } from '../../../modules/sanger/bioinfotongli/basicfitting/main'
include { BIOINFOTONGLI_BASICTRANSFORM     } from '../../../modules/sanger/bioinfotongli/basictransform/main'


workflow BASIC_HCS {

    take:
    zarr // channel: [  zarr  ]
    channel_index // channel: 0..4
    position_index // channel: 0..8
    time_index // channel: 0..50

    main:

    ch_versions = Channel.empty()

    BIOINFOTONGLI_BASICFITTING(
        zarr.combine(
            channel_index.combine(position_index).combine(time_index)
        )
    )
    ch_versions = ch_versions.mix(BIOINFOTONGLI_BASICFITTING.out.versions.first())

    basic_models = BIOINFOTONGLI_BASICFITTING.out.basic_models.groupTuple().map{ it ->
        [it[0].toInteger(), it[1].sort()] // group basic models by field. e.g. [field_id, [model1, model2, ...]]
    }
    
    fields = channel.fromPath("${params.zarr}/*/*/*", type: 'dir').map{ it ->
        String f = it.baseName
        String col = it.parent.baseName
        String row = it.parent.parent.baseName
        [f.toInteger(), row, col, file(it)] // field_id, field_path
    }
    to_correct = fields.combine(basic_models, by: 0) // join fields channel and basic_model channel models by field_id

    BIOINFOTONGLI_BASICTRANSFORM(to_correct)

    ch_versions = ch_versions.mix(BIOINFOTONGLI_BASICTRANSFORM.out.versions.first())

    emit:
    corrected_zarr      = BIOINFOTONGLI_BASICTRANSFORM.out.corrected_images           // channel: [ val(P), val(row), val(col), path(corrected_zarr) ]
    versions = ch_versions                     // channel: [ versions.yml ]
}

