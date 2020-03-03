project('aedi', 'd',
    meson_version: '>=0.37.1',
    subproject_dir: 'deps/subprojects',
    license: 'BSL-1.0',
    version: '1.0.0',
  )


project_soversion      = ''
project_version_suffix = ''
project_version        = meson.project_version()
project_version_full   = project_version + project_version_suffix

source_root = meson.source_root()
build_root = meson.build_root()

compiler = meson.get_compiler('d').get_id()
message(compiler)

if meson.get_compiler('d').get_id() == 'llvm'
endif
if meson.get_compiler('d').get_id() == 'dmd'
  if meson.is_subproject() == false
    add_global_arguments(
      '-lphobos2',
      '-ldruntime',
      '-ldl',
      '-lpthread',
      '-lm',
    )
  endif
endif
if meson.get_compiler('d').get_id() == 'gnu'
endif

aedi_src_d = include_directories('source/')

# Modules
# Aedi
subdir('source/aermicioi/aedi')
# Test 

deps = [
    ]

#
aedi_static_lib = static_library('aedi',
    [aermicioi_aedi_src],
    [aermicioi_aedi_util_src],
    include_directories : aedi_src_d,
    )

aedi_lib = library('aedi',
    [aermicioi_aedi_src],
    [aermicioi_aedi_util_src],
    include_directories : aedi_src_d,
    )

aedi_static_dep = declare_dependency(link_with : aedi_static_lib, include_directories : aedi_src_d)
aedi_dep = declare_dependency(link_with : aedi_lib, include_directories : aedi_src_d)


######## TESTING #########
# this option can be set by running the command if the meson build directory has not been initialised
# 
#       meson build-directory -Dbuild-tests=true
#
# or if the meson build directory has already been initialised
#       
#       meson configure -Dbuild-tests=true
#

if get_option('build-tests') == true
  aedi_test_bin = executable('aedi_unittest',
      [aermicioi_aedi_test_src],
      [aermicioi_aedi_src],
      include_directories : aedi_src_d,
      link_with : aedi_static_lib,
      )


  test('aedi_unittest', aedi_test_bin)
endif

######### EXAMPLES ############
# this option can be set by running the command if the meson build directory has not been initialised
# 
#       meson build-directory -Dbuild-examples=true
#
# or if the meson build directory has already been initialised
#       
#       meson configure -Dbuild-examples=true
#
if get_option('build-examples') == true
  subdir('examples/')
endif



