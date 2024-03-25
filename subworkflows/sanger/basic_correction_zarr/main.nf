include { BIOINFOTONGLI_BASICFITTING      } from '../../../modules/sanger/bioinfotongli/basicfitting/main'
include { BIOINFOTONGLI_BASICTRANSFORM     } from '../../../modules/sanger/bioinfotongli/basictransform/main'


process Generate_ome_zarr_stub { 

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'bioinfotongli/hcs_analysis:latest':
        'bioinfotongli/hcs_analysis:latest'}"
    storeDir params.out_dir

    input:
    path(zarr_root)

    output:
    path(new_ome_zarr), emit: ome_zarr_stub

    script:
    new_ome_zarr = zarr_root.baseName + "_corrected.zarr"
    """
    /opt/scripts/basic/Generate_ome_zarr_stub.py run \
        -zarr_in ${zarr_root} \
        -out_zarr_name "${new_ome_zarr}"
    """
}


workflow BASIC_CORRECTION_ZARR {

    take:
    ome_zarr // channel: [  zarr  ], which has to contain the OME-XML file in OME folder and the .zattrs file in the root

    main:

    ch_versions = Channel.empty()

    Generate_ome_zarr_stub(params.zarr)

    def jsonSlurper = new JsonSlurper()
    def md = jsonSlurper.parse(new File(params.zarr + "/.zattrs"))

    // Read the OME-XML file to get the number of channels. 
    def xmlFile = new File(params.zarr + "/OME/METADATA.ome.xml")
    def xml = new XmlParser().parse(xmlFile)
    def n_channel = xml.Image[0].Pixels[0].Channel.size()
    channels = (0..<n_channel).toList()

    def timepoints = [0] // not fully supported for bespoke values 

    if (md['plate'] == null) {
        fields = [-1]
        wells = channel.from(0..<xml.Image.size()).map{ it ->
            [['path': it, "rowIndex":"", "columnIndex":""], 
            file(params.zarr + "/" + it)]
        }
    } else {
        fields = (0..<md['plate']['field_count']).toList()
        wells = channel.from(md['plate']['wells']).map{ it ->
            [it, file(params.zarr + "/" + it['path'])]
        }
    }
    // The models are fitted for each channel, Z and field in the well.
    // Typically for each channel the models expect an array of shape (xxx, Z, Y, X)
    BIOINFOTONGLI_BASICFITTING(
        channel.from(ome_zarr)
            .combine(channel.from(fields))
            .combine(channel.from(channels))
            .combine(channel.from(timepoints))
    )
    ch_versions = ch_versions.mix(BIOINFOTONGLI_BASICFITTING.out.versions.first())

    basic_models = BIOINFOTONGLI_BASICFITTING.out.basic_models.groupTuple().map{ it ->
        [it[0].toInteger(), it[1].sort()] // group basic models by field. e.g. [field_id, [model1, model2, ...]]
    }
    BIOINFOTONGLI_BASICTRANSFORM(
        channel.from(fields).combine(wells).combine(basic_models, by: 0),
        Generate_ome_zarr_stub.out.ome_zarr_stub.name
    )
    ch_versions = ch_versions.mix(BIOINFOTONGLI_BASICTRANSFORM.out.versions.first())

    emit:
    corrected_ome_zarr      = BIOINFOTONGLI_BASICTRANSFORM.out.corrected_images           // channel: [ val(fov), val(well_info), path(corrected_images) ]
    versions = ch_versions                     // channel: [ versions.yml ]
}

