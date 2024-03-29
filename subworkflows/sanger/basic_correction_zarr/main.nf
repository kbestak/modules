import groovy.json.JsonSlurper
import groovy.xml.XmlParser
include { BIOINFOTONGLI_BASICFITTING      } from '../../../modules/sanger/bioinfotongli/basicfitting/main'
include { BIOINFOTONGLI_BASICTRANSFORM     } from '../../../modules/sanger/bioinfotongli/basictransform/main'


process Generate_ome_zarr_stub { 

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'bioinfotongli/basic_zarr:latest':
        'bioinfotongli/basic_zarr:latest'}"
    // storeDir params.out_dir
    publishDir params.out_dir, mode: 'copy'

    input:
    path(zarr_root)

    output:
    tuple val(meta), path(new_ome_zarr), emit: ome_zarr_stub
    path(fovs), emit: fovs 

    script:
    meta = [:]
    meta['id'] = zarr_root.baseName
    new_ome_zarr = zarr_root.baseName + "_corrected.zarr"
    fovs = "${new_ome_zarr}/fovs.json"
    """
    #/opt/scripts/basic/Generate_ome_zarr_stub.py run
    Generate_ome_zarr_stub.py run \
        -zarr_in ${zarr_root} \
        -out_zarr_name "${new_ome_zarr}" \
        -out_fov_json "${fovs}"
    """
}


workflow BASIC_CORRECTION_ZARR {

    take:
    zarrs // channel: [  zarr  ], which has to contain the OME-XML file in OME folder and at least the .zattrs file in the root

    main:
    ch_versions = Channel.empty()
    Generate_ome_zarr_stub(zarrs)
    datas = Generate_ome_zarr_stub.out.fovs.splitJson().multiMap{
        for_fitting: [it[0], it[1], it[2], it[3], it[4]]
        for_transforming: [it[0], it[2], it[1], it[5]]
    }
    // datas.for_fitting.unique().view()
    // datas.for_transforming.unique().view()

    // The models are fitted for each channel, Z and field in the well.
    // Typically for each channel the models expect an array of shape (xxx, Z, Y, X)
    BIOINFOTONGLI_BASICFITTING(datas.for_fitting.unique())
    ch_versions = ch_versions.mix(BIOINFOTONGLI_BASICFITTING.out.versions.first())

    basic_models = BIOINFOTONGLI_BASICFITTING.out.basic_models.groupTuple(by:[0, 1]).map{ it ->
        [it[0], it[1], it[2].sort()] // group basic models by field. e.g. [field_id, [model1, model2, ...]]
    }
    // basic_models.view()
    
    BIOINFOTONGLI_BASICTRANSFORM(
        datas.for_transforming.unique()
            .combine(basic_models, by: [0,1])
            .combine(Generate_ome_zarr_stub.out.ome_zarr_stub, by:0)
        // channel.from(fields).combine(wells).combine(basic_models, by: 0),
        // Generate_ome_zarr_stub.out.ome_zarr_stub.name
    )
    ch_versions = ch_versions.mix(BIOINFOTONGLI_BASICTRANSFORM.out.versions.first())

    emit:
    corrected_ome_zarr      = BIOINFOTONGLI_BASICTRANSFORM.out.corrected_images           // channel: [ val(fov), val(well_info), path(corrected_images) ]
    versions = ch_versions                     // channel: [ versions.yml ]
}

