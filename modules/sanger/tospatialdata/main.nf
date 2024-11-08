process TOSPATIALDATA {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'bioinfotongli/spatialdata:latest':
        'bioinfotongli/spatialdata:latest' }"
    publishDir params.out_dir

    input:
    tuple val(meta), path(xenium_input)

    output:
    tuple val(meta), path(sdata_out), emit: sdata
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    sdata_out = "${prefix}.sdata"
    """
    /scripts/to_spatialdata.py run \\
        --xenium_input ${xenium_input} \\
        --out_name ${sdata_out} \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tospatialdata: \$(/scripts/to_spatialdata.py version)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    sdata_out = "${prefix}.sdata"
    """
    touch ${sdata_out}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tospatialdata: \$(/scripts/to_spatialdata.py version)
    END_VERSIONS
    """
}
