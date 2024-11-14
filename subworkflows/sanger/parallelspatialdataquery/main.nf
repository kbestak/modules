container_version = "0.2.2"

params.spatialdatas = [
    [["id":"sdata1"], "spatialdata1"],
    [["id":"sdata2"], "spatialdata2"],
]
params.debug=false


process GENERATE_POLYGON_INDEXES {
    tag "${meta.id}"
    debug params.debug

    label "medium_mem"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        "quay.io/bioinfotongli/spatialdata:${container_version}":
        "quay.io/bioinfotongli/spatialdata:${container_version}"}"

    publishDir params.out_dir + "/spatialdata_polygon_indexes"

    input:
    tuple val(meta), path(sdata)

    output:
    tuple val(meta), path("${meta.id}/*.json"), emit: polygon_indexes
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''  
    """
    /opt/conda/bin/python /scripts/partition_polygons.py run \
        --sdata ${sdata} \
        --out_name ${meta.id} \
        ${args}
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        : \$(echo \$(/scripts/partition_polygons.py version 2>&1) | sed 's/^.*partition_polygons.py //; s/Using.*\$//' ))
    END_VERSIONS
    """
}


process CROP_SPATIALDATA {
    tag "${meta.id}"
    debug params.debug

    label "medium_mem"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        "quay.io/bioinfotongli/spatialdata:${container_version}":
        "quay.io/bioinfotongli/spatialdata:${container_version}"}"

    publishDir params.out_dir + "/cropped_spatialdata"

    input:
    tuple val(meta), path(sdata), path(index_json)

    output:
    tuple val(meta), path("${meta.id}/*.sdata"), emit: cropped_sdatas
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''  
    """
    /opt/conda/bin/python /scripts/crop.py run \
        --sdata ${sdata} \
        --index_json ${index_json} \
        --out_name ${meta.id} \
        ${args}
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        : \$(echo \$(/scripts/crop.py version 2>&1) | sed 's/^.*crop.py //; s/Using.*\$//' ))
    END_VERSIONS
    """
}


workflow PARALLELSPATIALDATAQUERY {
    take:
    spatialdatas 

    main:
    ch_versions = Channel.empty()
    GENERATE_POLYGON_INDEXES(spatialdatas)
    ch_versions = ch_versions.mix(GENERATE_POLYGON_INDEXES.out.versions.first())

    for_cropping = spatialdatas.combine(GENERATE_POLYGON_INDEXES.out.polygon_indexes, by:0)
        .flatMap { meta, zarr, jsons ->
            if (jsons instanceof List) {
                jsons.collect { json -> [meta, zarr, json] }
            } else {
                [[meta, zarr, jsons]]
            }
        }
    
    CROP_SPATIALDATA(for_cropping)
    ch_versions = ch_versions.mix(CROP_SPATIALDATA.out.versions.first())

    emit:
    crops       = CROP_SPATIALDATA.out.cropped_sdatas   // channel: [ val(meta), [ crops ] ]
    versions    = ch_versions                     // channel: [ versions.yml ]
}