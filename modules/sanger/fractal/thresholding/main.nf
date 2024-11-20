container_version = "0.0.1"

process FRACTAL_THRESHOLDING {
    tag "$meta.id"
    label 'process_low'

    // conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        "quay.io/bioinfotongli/hcs_fractal:${container_version}":
        "quay.io/bioinfotongli/hcs_fractal:${container_version}" }"
    publishDir params.out_dir + "/thresholding_segmentation/"

    input:
    tuple val(meta), path(ome_zarr), val(threshold), val(label_name), val(channel_name)

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
        "threshold": ${threshold},
        "label_name": "${label_name}",
        "channel": {
            "label": "${channel_name}"
        },
        "zarr_url": "${ome_zarr}"
    }' > input.json
    /opt/conda/bin/python /opt/scripts/thresholding_label_task.py --args-json input.json $args --out-json dummy.json

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
        modified_path: $omezarr_root/Features.csv
    END_VERSIONS
    """
}
