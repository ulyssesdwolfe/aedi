configuration_primitives_src = files(
        'source/configuration_primitives.d'
        )

configuration_primitives_bin = executable(
        'configuration_primitives-bin',
        [configuration_primitives_src],
        [aermicioi_aedi_src],
        [aermicioi_aedi_util_src],
        include_directories : [aedi_src_d]
        )


