process MACSIMA2MC {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "ghcr.io/schapirolabor/macsima2mc:v1.3.0"

    input:
    tuple val(meta), path(input_dir), val(output_dir)

    output:
    tuple val(meta), path("${output_dir}/*")    , emit: out_dir
    tuple val("${task.process}"), val('macsima2mc'), eval("macsima2mc --version"), topic: versions, emit: versions_macsima2mc
    tuple val("${task.process}"), val('basicpy'), eval("python -m pip show basicpy | grep 'Version' | sed -e 's/Version: //g'"), topic: versions, emit: versions_basicpy

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    macsima2mc \\
        -i ${input_dir} \\
        -o ${output_dir} \\
        $args

    find ${output_dir} -name "*.ome.tiff" | while read f; do
        sed -i -E 's/UUID="urn:uuid:[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}"/                                                    /g' "\$f"
    done
    """

    stub:
    def args = task.ext.args ?: ''
    """
    echo $args

    mkdir ${output_dir}
    mkdir ${output_dir}/well-rack-roi-exp
    touch ${output_dir}/well-rack-roi-exp/markers.csv
    mkdir ${output_dir}/well-rack-roi-exp/raw
    touch ${output_dir}/well-rack-roi-exp/raw/well-rack-roi-exp.ome.tif
    """
}
