container_version = "0.0.1"

process BIOINFOTONGLI_THRESHOLDING {
    tag "$meta.id"
    label 'process_low'

    // conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        "quay.io/bioinfotongli/ome-zarr-nextflow-minimum:${container_version}":
        "quay.io/bioinfotongli/ome-zarr-nextflow-minimum:${container_version}" }"
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
    json_content='{
        "threshold": 5,
        "label_name": "threshold",
        "channel_name": "DAPI"
    }'

    echo "$json_content" > input.json
    ls
    python /scripts/thresholding_label_task.py --args-json input.json $args

    cat <<-END_VERSIONS > ${omezarr_root}/${label_name}
    "${task.process}":
        thresholding: \$(echo \$(/scripts/thresholding_label_task.py version 2>&1 | sed 's/^.*thresholding_label_task.py //; s/Using.*\$//' ))
        timestamp: \$(date)
        modified_path: $omezarr_root/Features.csv
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    """
    touch ${ome_zarr}/images/${label_name}.npy

    cat <<-END_VERSIONS > ${omezarr_root}/${label_name}
    "${task.process}":
        thresholding: \$(echo \$(/scripts/thresholding_label_task.py version 2>&1 | sed 's/^.*thresholding_label_task.py //; s/Using.*\$//' ))
        timestamp: \$(date)
        modified_path: $omezarr_root/Features.csv
    END_VERSIONS
    """
}
