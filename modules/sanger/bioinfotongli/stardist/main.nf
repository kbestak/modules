process BIOINFOTONGLI_STARDIST {
    tag "$meta.id"
    label 'process_medium'

    // conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'quay.io/cellgeni/tiled_stardist:0.9.1':
        'quay.io/cellgeni/tiled_stardist:0.9.1' }"

    input:
    tuple val(meta), val(x_min), val(x_max), val(y_min), val(y_max), path(image)

    output:
    tuple val(meta), path("*.wkt"), emit: outlines
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    stardist_helper.py run \\
        --image-path $image \\
        --x_min $x_min \\
        --x_max $x_max \\
        --y_min $y_min \\
        --y_max $y_max \\
        --output ${prefix}.wkt \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioinfotongli: \$(stardist_helper.py --version)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.wkt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioinfotongli: \$(stardist_helper.py --version)
    END_VERSIONS
    """
}
