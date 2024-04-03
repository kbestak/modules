process BIOINFOTONGLI_OMEZARRPARSE {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'bioinfotongli/omezarrparse':
        'bioinfotongli/omezarrparse' }"
    storeDir params.out_dir

    input:
    tuple val(meta), path(ome_zarr_root)

    output:
    path(params_in_json), emit: fovs_to_process
    tuple val(meta), path(out_zarr_name), emit: out_ome_zarr_with_meta
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    out_zarr_name = prefix + ".zarr"
    params_in_json = prefix + ".json"
    """
    /opt/scripts/Generate_ome_zarr_stub.py run \\
        -zarr_in $ome_zarr_root \\
        -out_zarr_name $out_zarr_name \\
        -out_fov_json $params_in_json \\
        $args \\

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioinfotongli: \$(/opt/scripts/Generate_ome_zarr_stub.py version)
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
        bioinfotongli: \$(/opt/scripts/Generate_ome_zarr_stub.py version)
    END_VERSIONS
    """
}
