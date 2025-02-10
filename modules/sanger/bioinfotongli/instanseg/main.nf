process BIOINFOTONGLI_INSTANSEG {
    tag "$meta.id"
    label 'process_medium'
    label "gpu"

    // conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'quay.io/cellgeni/instanseg:v0.0.1':
        'quay.io/cellgeni/instanseg:v0.0.1' }"

    input:
    tuple val(meta), val(x_min), val(y_min), val(x_max), val(y_max), path(img)

    output:
    tuple val(meta), path("${prefix}.wkt"), emit: wkts
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    instanseg_helper.py run \\
        -image-path ${img} \\
        -x-min ${x_min} \\
        -y-min ${y_min} \\
        -x-max ${x_max} \\
        -y-max ${y_max} \\
        -output ${prefix}.wkt \\
        $args \\

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioinfotongli: \$(instanseg_helper.py version)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.wkt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioinfotongli: \$(instanseg_helper.py version)
    END_VERSIONS
    """
}
