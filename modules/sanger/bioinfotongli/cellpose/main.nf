process BIOINFOTONGLI_CELLPOSE {
    tag "${meta.id}"

    label "gpu"
    label "medium_mem"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        "quay.io/cellgeni/tiled_cellpose:0.1.1":
        "quay.io/cellgeni/tiled_cellpose:0.1.1"}"
    containerOptions = {
            workflow.containerEngine == "singularity" ? "--cleanenv --nv":
            ( workflow.containerEngine == "docker" ? "--gpus all": null )
    }

    publishDir params.out_dir + "/naive_cellpose_segmentation"

    input:
    tuple val(meta), val(x_min), val(y_min), val(x_max), val(y_max), path(image), val(cell_diameter)

    output:
    tuple val(meta), path("${stem}/${stem}_cp_outlines.txt"), emit: outlines, optional: true
    tuple val(meta), path("${stem}/${stem}_cp_outlines.wkt"), emit: wkts
    tuple val(meta), path("${stem}/${stem}*png"), emit: cp_plots, optional: true
    path "versions.yml"           , emit: versions

    script:
    stem = "${meta.id}-${x_min}_${y_min}_${x_max}_${y_max}-diam_${cell_diameter}"
    def args = task.ext.args ?: ''  
    """
    cellpose_seg.py run \
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
