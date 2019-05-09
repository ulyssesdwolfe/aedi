project('aedi', 'd',
    meson_version: '>=0.37.1',
    subproject_dir: 'deps/subprojects',
    license: 'BSL-1.0',
    version: '1.0.0'
  )


project_soversion      = ''
project_version_suffix = ''
project_version        = meson.project_version()
project_version_full   = project_version + project_version_suffix

source_root = meson.source_root()
build_root = meson.build_root()


if meson.get_compiler('d').get_id() == 'llvm'
endif
if meson.get_compiler('d').get_id() == 'dmd'
endif
if meson.get_compiler('d').get_id() == 'gnu'
endif

aedi_src_d = include_directories('source/')

# Modules
# Aedi
subdir('source/aermicioi/aedi')
# Util
subdir('source/aermicioi/util')
# Test 
subdir('source/aermicioi/aedi/test')

deps = [
    ]

#
aedi_lib = static_library('aedi',
    [aermicioi_aedi_src],
    [aermicioi_util_src],
    include_directories : aedi_src_d,
    dependencies : [deps],
    version: project_version, 
    soversion : project_soversion
    )

aedi_dep = declare_dependency(link_with : aedi_lib, include_directories : aedi_src_d)


######## UNIT TESTING #########

aedi_test_bin = executable('aedi_unittest',
    [aermicioi_aedi_test_src],
    [aermicioi_aedi_src],
    [aermicioi_util_src],
    include_directories : aedi_src_d,
    dependencies : [deps],
    d_args : meson.get_compiler('d').unittest_args(),
    link_args : '-main'
    )


test('aedi_unittest', aedi_test_bin)




######### EXAMPLES ############

#subdir('examples/')



