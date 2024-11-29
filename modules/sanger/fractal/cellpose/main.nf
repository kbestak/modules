container_version = "0.0.1"


process FRACTAL_CELLPOSE {
    tag "$meta.id"
    label 'process_low'

    // conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        "quay.io/bioinfotongli/hcs_fractal:${container_version}":
        "quay.io/bioinfotongli/hcs_fractal:${container_version}" }"
    publishDir params.out_dir + "/cellpose_segmentation/"

    input:
    tuple val(meta), path(ome_zarr), val(level), val(channel_name), val(label_name)

    output:
    tuple val(meta), path("${ome_zarr}/labels/${label_name}"), emit: thresholded_segmentation
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    echo '
    {
        "level": "${level}",
        "channel": {
            "label": "${channel_name}"
        },
        "zarr_url": "${ome_zarr}",
        "output_label_name": "${label_name}"
    }' > input.json
    /opt/conda/bin/python /opt/conda/lib/python3.11/site-packages/fractal_tasks_core/tasks/cellpose_segmentation.py --args-json input.json $args --out-json dummy.json

    #cat <<-END_VERSIONS > ${ome_zarr}/${label_name}
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        thresholding: \$(echo \$(/opt//scripts/thresholding_label_task.py version 2>&1 | sed 's/^.*thresholding_label_task.py //; s/Using.*\$//' ))
        timestamp: \$(date)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    """
    touch ${ome_zarr}/images/${label_name}.npy

    #cat <<-END_VERSIONS > ${omezarr_root}/${label_name}
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        thresholding: \$(echo \$(/scripts/thresholding_label_task.py version 2>&1 | sed 's/^.*thresholding_label_task.py //; s/Using.*\$//' ))
        timestamp: \$(date)
    END_VERSIONS
    """
}
