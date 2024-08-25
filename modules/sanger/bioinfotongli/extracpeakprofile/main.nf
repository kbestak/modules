process BIOINFOTONGLI_EXTRACPEAKPROFILE {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'bioinfotongli/extract_peak_profile:latest':
        'bioinfotongli/extract_peak_profile:latest' }"

    input:
    tuple val(meta), path(image), path(peaks)

    output:
    tuple val(meta), path("${prefix}.npy"), emit: peak_profile
    tuple val(meta), path("${prefix}.csv"), emit: peak_locations
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}_peak_profile"
    """
    /scripts/extract_peak_profile.py run \\
        --image ${image} \\
        --peaks ${peaks} \\
        --stem ${prefix} \\
        $args \\

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioinfotongli: \$(/scripts/extract_peak_profile.py version |& sed '1!d ; s//extract_peak_profile.py //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}_peak_profile"
    """
    touch ${prefix}.npy

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioinfotongli: \$(/scripts/extract_peak_profile.py version |& sed '1!d ; s//extract_peak_profile.py //')
    END_VERSIONS
    """
}
