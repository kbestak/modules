process BIOINFOTONGLI_ASSIGNSPOTS2D {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'bioinfotongli/assign:latest':
        'bioinfotongli/assign:latest' }"

    input:
    tuple val(meta), path(peaks), path(label_2d)

    output:
    tuple val(meta), path(out_csv), emit: count_matrix
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    out_csv = "${prefix}_count_matrix.csv"
    """
    /scripts/assignment.py run \\
        --label_image ${label_2d} \\
        --transcripts ${peaks} \\
        --out_name ${out_csv} \\
        $args \\

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioinfotongli: \$(/scripts/assignment.py version |& sed '1!d ; s/samtools //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    out_csv = "${prefix}_count_matrix.csv"
    """
    touch ${out_csv}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioinfotongli: \$(/scripts/assignment.py version |& sed '1!d ; s/samtools //')
    END_VERSIONS
    """
}