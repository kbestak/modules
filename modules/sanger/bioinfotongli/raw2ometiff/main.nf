VERSION = '0.5.0'

process BIOINFOTONGLI_RAW2OMETIFF {
    tag "$meta.id"
    label 'process_medium'

    conda (params.enable_conda ? "-c ome raw2ometiff=${VERSION}" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        "openmicroscopy/raw2ometiff:${VERSION}":
        "openmicroscopy/raw2ometiff:${VERSION}" }"

    input:
    tuple val(meta), path(ome_zarr)

    output:
    tuple val(meta), path("${prefix}.ome.tif"), emit: ome_tif
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    raw2ometiff \\
        --max_workers=$task.cpus \\
        $args \\
        -o ${prefix}.ome.tif \\
        $ome_zarr \\

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioinfotongli: \$(echo \$(raw2ometiff --version 2>&1) | sed 's/^.*raw2ometiff //; s/Using.*\$//' ))
    END_VERSIONS
    """
}
