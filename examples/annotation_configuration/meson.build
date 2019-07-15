
annotation_configuration_src = files(
        'source/annotation_configuration.d'
        )


annotation_configuration_bin = executable(
        'annotation_configuration-bin',
        [annotation_configuration_src],
        [aermicioi_aedi_src],
        [aermicioi_aedi_util_src],
        include_directories : [aedi_src_d]
        )


