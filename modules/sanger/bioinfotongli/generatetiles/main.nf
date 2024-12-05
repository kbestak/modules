process BIOINFOTONGLI_GENERATETILES {
    tag "${meta.id}"

    label "small_mem"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        "quay.io/bioinfotongli/large_image_io:0.0.2":
        "quay.io/bioinfotongli/large_image_io:0.0.2"}"

    publishDir params.out_dir + "/tile_coords"

    input:
    tuple val(meta), path(image)

    output:
    tuple val(meta), path("${stem}/${out_name}"), emit: tile_coords
    path "versions.yml"           , emit: versions

    script:
    stem = meta.id
    out_name = "tile_coords.csv"
    def args = task.ext.args ?: ''  
    """
    tile_2D_image.py run \\
        --image ${image} \\
        --out_dir "${stem}" \\
        --out_name "${out_name}" \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        : \$(echo \$(tile_2D_image.py version))
    END_VERSIONS
    """
}