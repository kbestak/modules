process BIOINFOTONGLI_BASICFITTING {
    tag "C:$C P:$P T:$T"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'bioinfotongli/basic_zarr:latest':
        'bioinfotongli/basic_zarr:latest'}"
    // containerOptions "${workflow.containerEngine == 'singularity' ? '--nv':'--gpus all'}" // GPU memory is not enough to load all tiles at once
    storeDir params.out_dir + "/BaSiC_models/"

    input:
    tuple path(zarr_root), val(C), val(P), val(T)

    output:
    tuple val(P), path(expected_model_dir), emit: basic_models 
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    expected_model_dir = "BaSiC_model_C${C}_P${P}_T${T}"
    """
    /opt/BaSiC_fitting.py run \
        -zarr ${zarr_root} \
        -C ${C} \
        -P ${P} \
        -T ${T} \
        -out ${expected_model_dir} \
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioinfotongli: \$(/opt/basic_fitting.py version)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    """
    mkdir BaSiC_model_C0_P0_T0

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioinfotongli: \$(/opt/basic_fitting.py version)
    END_VERSIONS
    """
}
