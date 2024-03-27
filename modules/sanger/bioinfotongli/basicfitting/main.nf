process BIOINFOTONGLI_BASICFITTING {
    tag "C:$C Field:$field T:$T"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'bioinfotongli/basic_zarr:latest':
        'bioinfotongli/basic_zarr:latest'}"
    // containerOptions "${workflow.containerEngine == 'singularity' ? '--nv':'--gpus all'}" // GPU memory is not enough to load all tiles at once
    publishDir params.out_dir + "/BaSiC_models/", mode: 'copy'

    input:
    tuple path(zarr_root), val(field), val(C), val(T)

    output:
    tuple val(meta), val(field), path(expected_model_dir), emit: basic_models 
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    expected_model_dir = "${zarr_root}/BaSiC_model_F${field}_C${C}_T${T}"
    meta = [:]
    meta["id"] = zarr_root
    """
    /opt/scripts/basic/BaSiC_fitting.py run \
        -zarr ${zarr_root} \
        -field ${field} \
        -C ${C} \
        -T ${T} \
        -out ${expected_model_dir} \
        ${args} 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioinfotongli: \$(/opt/scripts/basic/BaSiC_fitting.py version)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    expected_model_dir = "BaSiC_model_F${field}_C${C}_T${T}"
    """
    mkdir ${expected_model_dir}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioinfotongli: \$(/opt/scripts/basic/BaSiC_fitting.py version)
    END_VERSIONS
    """
}
