params.images = [
    [["id":"test1"], "file1"],
    [["id":"test2"], "file2"],
]
params.cell_diameters = [30, 40]
params.cellpose_model_dir = "/lustre/scratch126/cellgen/cellgeni/tl10/cellpose_models"

container_version = "latest"

process SLICE {
    debug params.debug

    label "small_mem"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        "tiled_cellpose:${container_version}":
        "tiled_cellpose:${container_version}"}"

    storeDir params.out_dir + "/slice_jsons"

    input:
    tuple val(meta), path(file_in)

    output:
    tuple val(meta), path("${stem}/slices.csv")

    script:
    stem = meta.id
    def args = task.ext.args ?: ''  
    """
    /scripts/slice_image.py run \\
        --image ${file_in} \\
        --out ${stem} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        : \$(echo \$(/scripts/slice_image.py version 2>&1) | sed 's/^.*slice_image.py //; s/Using.*\$//' ))
    END_VERSIONS
    """
}


process CELLPOSE {
    debug params.debug

    label "gpu"
    label "medium_mem"
    maxForks 5

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        "tiled_cellpose:${container_version}":
        "tiled_cellpose:${container_version}"}"

    storeDir params.out_dir + "/cellpose_segmentation"

    input:
    tuple val(meta), val(x_min), val(y_min), val(x_max), val(y_max), path(image), val(cell_diameter)

    output:
    tuple val(meta), path("${stem}/${stem}_cp_outlines.txt"), emit: outlines, optional: true
    tuple val(meta), path("${stem}/${stem}_cp_outlines.wkt"), emit: wkts
    tuple val(meta), path("${stem}/${stem}*png"), emit: cp_plots, optional: true
    // tuple val(stem), path("${meta.id}-${stem}/${stem}*tif"), emit: cp_out, optional: true

    script:
    baseName = "${x_min}_${y_min}_${x_max}_${y_max}"
    stem = "${meta.id}-${baseName}"
    def args = task.ext.args ?: ''  
    """
    export CELLPOSE_LOCAL_MODELS_PATH=/cellpose_models
    /scripts/cellpose_seg.py run \
        --image ${image} \
        --x_min ${x_min} \
        --y_min ${y_min} \
        --x_max ${x_max} \
        --y_max ${y_max} \
        --cell_diameter ${cell_diameter} \
        --out_dir "${stem}" \
        ${args}
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        : \$(echo \$(/scripts/cellpose_seg.py version 2>&1) | sed 's/^.*cellpose_seg.py //; s/Using.*\$//' ))
    END_VERSIONS
    """
}


process MERGE_OUTLINES {
    debug params.debug

    label "medium_mem"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        "tiled_cellpose:${container_version}":
        "tiled_cellpose:${container_version}"}"

    storeDir params.out_dir + "/cellpose_segmentation_outlines"

    input:
    tuple val(meta), path(wkts)

    output:
    tuple val(meta), path("${meta.id}_merged.wkt"), emit: merged_wkt
    tuple val(meta), path("${meta.id}_merged.geojson"), emit: merged_geojson

    script:
    def args = task.ext.args ?: ''  
    """
    /scripts/merge_wkts.py run \
        --sample_id ${meta.id} \
        ${wkts} \
        ${args}
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        : \$(echo \$(/scripts/merge_wkts.py version 2>&1) | sed 's/^.*merge_wkts.py //; s/Using.*\$//' ))
    END_VERSIONS
    """
}

workflow TILED_CELLPOSE {
    take:
    images 

    main:
    ch_versions = Channel.empty()
    SLICE(images)
    ch_versions = ch_versions.mix(SLICE.out.versions.first())

    images_slices = SLICE.out.splitCsv(header:true, sep:",").map{ meta, coords ->
        [meta, coords.X1, coords.Y1, coords.X2, coords.Y2]
    }.combine(images, by:0).combine(channel.from(params.cell_diameters))
    CELLPOSE(images_slices)
    ch_versions = ch_versions.mix(CELLPOSE.out.versions.first())

    MERGE_OUTLINES(CELLPOSE.out.wkts.groupTuple())
    ch_versions = ch_versions.mix(MERGE_OUTLINES.out.versions.first())

    emit:
    wkt         = MERGE_OUTLINES.out.merged_wkt   // channel: [ val(meta), [ wkt ] ]
    versions    = ch_versions                     // channel: [ versions.yml ]
}