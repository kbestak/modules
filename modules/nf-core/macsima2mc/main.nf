process MACSIMA2MC {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "ghcr.io/schapirolabor/macsima2mc:v1.2.15"
    // Container version is pinned to v1.2.15 (latest) due to small code-unrelated bumps, but the macsima2mc package inside hasn't changed since v1.2.6
    // Semantic versioning will continue from 1.3 onward.

    input:
    tuple val(meta), path(input_dir), val(output_dir)

    output:
    tuple val(meta), path("${output_dir}/*")    , emit: out_dir
    tuple val("${task.process}"), val('macsima2mc'), eval('python -m pip show macsima2mc | grep "Version" | sed -e "s/Version: //g"'), topic: versions, emit: versions_macsima2mc

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args   ?: ''
    """
    macsima2mc \
        -i ${input_dir} \
        -o ${output_dir} \
        ${args}

    find ${output_dir} -name "*.ome.tiff" | while read f; do
        sed -i -E 's/UUID="urn:uuid:[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}"/                                                    /g' "\$f"
    done
    """

    stub:
    """
    mkdir ${output_dir}
    mkdir ${output_dir}/well-rack-roi-exp
    touch ${output_dir}/well-rack-roi-exp/markers.csv
    mkdir ${output_dir}/well-rack-roi-exp/raw
    touch ${output_dir}/well-rack-roi-exp/raw/well-rack-roi-exp.ome.tif
    """
}
