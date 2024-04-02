process BIOINFOTONGLI_OMEZARRPARSE {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'bioinfotongli/omezarrparse':
        'bioinfotongli/omezarrparse' }"

    input:
    tuple val(meta), path(ome_zarr_root)

    output:
    tuple val(meta), path(params_in_json), emit: params_in_json
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    params_in_json = file(ome_zarr_root).baseName + ".json"
    """
    /opt/scripts/ome_zarr_parse.py run \\
        -zarr_path $params_in_json \\
        -out_params_json $ome_zarr_root \\
        $args \\

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioinfotongli: \$(/opt/scripts/ome_zarr_parse.py version)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    params_in_json = file(ome_zarr_root).baseName + ".json"
    """
    touch ${params_in_json}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioinfotongli: \$(/opt/scripts/ome_zarr_parse.py version)
    END_VERSIONS
    """
}
