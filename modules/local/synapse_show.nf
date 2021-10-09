// Import generic module functions
include { initOptions; saveFiles; getSoftwareName; getProcessName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process SYNAPSE_SHOW {
    tag "$id"
    label 'process_low'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), meta:[:], publish_by_meta:[]) }

    conda (params.enable_conda ? "bioconda::synapseclient=2.4.0" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/synapseclient:2.4.0--pyh5e36f6f_0"
    } else {
        container "quay.io/biocontainers/synapseclient:2.4.0--pyh5e36f6f_0"
    }

    input:
    val id
    path config

    output:
    path "*.txt"       , emit: metadata
    path "versions.yml", emit: versions

    script:
    """
    synapse \\
        -c $config \\
        show \\
        $options.args \\
        $id \\
        | sed -n '1,3p;15,16p;20p;23p' > ${id}.metadata.txt

    cat <<-END_VERSIONS > versions.yml
    ${getProcessName(task.process)}:
        ${getSoftwareName(task.process)}: \$(synapse --version | sed -e "s/Synapse Client //g")
    END_VERSIONS
    """
}
