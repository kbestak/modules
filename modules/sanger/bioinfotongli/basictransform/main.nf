process BIOINFOTONGLI_BASICTRANSFORM {
    tag "C:$C P:$P T:$T"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'bioinfotongli/basic_zarr:latest':
        'bioinfotongli/basic_zarr:latest' }"
    storeDir params.out_dir

    input:
    tuple val(fov), val(well_info), path(field), path(models)
    val(new_zarr_root) 

    output:
    tuple val(fov), val(well_info), path(expected_dir), emit: corrected_images
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def internal_path_to_root = well_info['path'] + "/"
    fov_to_correct = fov == -1 ? field: "${field}/${fov}"
    expected_dir = fov == -1 ? "${new_zarr_root}/${internal_path_to_root}":"${new_zarr_root}/${internal_path_to_root}${fov}"
    """
    /opt/scripts/basic/BaSiC_transforming.py run \
        -field ${fov_to_correct} \
        -out_dir "${expected_dir}" \
        ${args}
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioinfotongli: \$(/opt/scripts/basic/BaSiC_transforming.py version) 
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    expected_dir = row == -1 ? "corrected/${F}":"corrected/${row}/${col}/${F}"
    """
    mkdir ${expected_dir}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioinfotongli: \$(/opt/scripts/basic/BaSiC_transforming.py version)
    END_VERSIONS
    """
}
