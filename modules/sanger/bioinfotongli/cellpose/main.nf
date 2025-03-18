process BIOINFOTONGLI_CELLPOSE {
    tag "${meta.id}"

    label "medium_mem"

    // container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //     "quay.io/cellgeni/tiled_cellpose:0.1.3":
    //     "quay.io/cellgeni/tiled_cellpose:0.1.3"}"
    container "quay.io/cellgeni/tiled_cellpose:0.1.3"
    // containerOptions = {
    //         workflow.containerEngine == "singularity" ? "--cleanenv --nv":
    //         ( workflow.containerEngine == "docker" ? "--gpus all": null )
    // }

    publishDir params.out_dir + "/naive_cellpose_segmentation"

    input:
    tuple val(meta), val(x_min), val(y_min), val(x_max), val(y_max), path(image), val(cell_diameter)

    output:
    tuple val(meta), path("${prefix}/${prefix}_cp_outlines.txt"), emit: outlines, optional: true
    tuple val(meta), path("${prefix}/${prefix}_cp_outlines.wkt"), emit: wkts
    tuple val(meta), path("${prefix}/${prefix}*png"), emit: cp_plots, optional: true
    path "versions.yml"           , emit: versions

    script:
    prefix = "${meta.id}-${x_min}_${y_min}_${x_max}_${y_max}-diam_${cell_diameter}"
    def args = task.ext.args ?: ''
    """
    export NUMBA_CACHE_DIR=\$PWD
    cellpose_seg.py run \
        --image ${image} \
        --x_min ${x_min} \
        --y_min ${y_min} \
        --x_max ${x_max} \
        --y_max ${y_max} \
        --cell_diameter ${cell_diameter} \
        --out_dir "${prefix}" \
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        : \$(echo \$(cellpose_seg.py version))
    END_VERSIONS
    """


    stub:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}-${x_min}_${y_min}_${x_max}_${y_max}-diam_${cell_diameter}"
    """
    mkdir "${prefix}"
    touch "${prefix}/${prefix}_cp_outlines.wkt"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioinfotongli: \$(cellpose_seg.py version)
    END_VERSIONS
    """
}
