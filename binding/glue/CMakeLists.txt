# Enable policy to not use RPATH settings for install_name on macOS.
if(POLICY CMP0068)
  cmake_policy(SET CMP0068 NEW)
endif()

# Consider changing the project name to something relevant for you.
# project(SampleBinding)

# ================================ General configuration ======================================

# Set CPP standard to C++11 minimum.
set(CMAKE_CXX_STANDARD 11)

# The sample library for which we will create bindings. You can change the name to something
# relevant for your project.
set(sample_library "libfoo.so")

# The name of the generated bindings module (as imported in Python). You can change the name
# to something relevant for your project.
set(bindings_library "foo")

# The header file with all the types and functions for which bindings will be generated.
# Usually it simply includes other headers of the library you are creating bindings for.

set(wrapped_header ${CMAKE_CURRENT_SOURCE_DIR}/bindings.h)

# The typesystem xml file which defines the relationships between the C++ types / functions
# and the corresponding Python equivalents.
set(typesystem_file ${CMAKE_CURRENT_SOURCE_DIR}/bindings.xml)

# Specify which C++ files will be generated by shiboken. This includes the module wrapper
# and a '.cpp' file per C++ type. These are needed for generating the module shared
# library.
set(generated_sources
    ${CMAKE_CURRENT_BINARY_DIR}/${bindings_library}/foo_module_wrapper.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/${bindings_library}/abq_counter_wrapper.cpp)

set(foo_source_dir ${CMAKE_CURRENT_SOURCE_DIR}/../../src)
set(foo_lib_dir ${CMAKE_CURRENT_SOURCE_DIR}/../../lib)

# ================================== Shiboken detection ======================================
# Use provided python interpreter if given.
if(NOT python_interpreter)
    find_program(python_interpreter "python")
endif()
message(STATUS "Using python interpreter: ${python_interpreter}")

set(PYSIDE2_DIR ${Python3_SITELIB}/PySide2)

# Macro to get various pyside / python include / link flags and paths.
# Uses the not entirely supported utils/pyside2_config.py file.
macro(pyside2_config option output_var)
    if(${ARGC} GREATER 2)
        set(is_list ${ARGV2})
    else()
        set(is_list "")
    endif()

    execute_process(
      # COMMAND ${python_interpreter} "${CMAKE_SOURCE_DIR}/../utils/pyside2_config.py"
      COMMAND ${python_interpreter} "${PYSIDE2_DIR}/examples/utils/pyside2_config.py"
              ${option}
      OUTPUT_VARIABLE ${output_var}
      OUTPUT_STRIP_TRAILING_WHITESPACE)

    if ("${${output_var}}" STREQUAL "")
        message(FATAL_ERROR "Error: Calling pyside2_config.py ${option} returned no output.")
    endif()
    if(is_list)
        string (REPLACE " " ";" ${output_var} "${${output_var}}")
    endif()
endmacro()

# Query for the shiboken generator path, Python path, include paths and linker flags.
pyside2_config(--shiboken2-module-path shiboken2_module_path)
pyside2_config(--shiboken2-generator-path shiboken2_generator_path)
pyside2_config(--python-include-path python_include_dir)
pyside2_config(--shiboken2-generator-include-path shiboken_include_dir 1)
pyside2_config(--shiboken2-module-shared-libraries-cmake shiboken_shared_libraries 0)
pyside2_config(--python-link-flags-cmake python_linking_data 0)

set(shiboken_path "${shiboken2_generator_path}/shiboken2${CMAKE_EXECUTABLE_SUFFIX}")
if(NOT EXISTS ${shiboken_path})
    message(FATAL_ERROR "Shiboken executable not found at path: ${shiboken_path}")
endif()


# ==================================== RPATH configuration ====================================


# =============================================================================================
# !!! (The section below is deployment related, so in a real world application you will want to
# take care of this properly with some custom script or tool).
# =============================================================================================
# Enable rpaths so that the built shared libraries find their dependencies.
set(CMAKE_SKIP_BUILD_RPATH FALSE)
set(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)
set(CMAKE_INSTALL_RPATH ${shiboken2_module_path} ${CMAKE_CURRENT_SOURCE_DIR} ${QtCore_libdir})
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
# =============================================================================================
# !!! End of dubious section.
# =============================================================================================


# =============================== CMake target - sample_library ===============================


# Define the sample shared library for which we will create bindings.
# set(${sample_library}_sources icecream.cpp truck.cpp)
# add_library(${sample_library} SHARED ${${sample_library}_sources})
# set_property(TARGET ${sample_library} PROPERTY PREFIX "")

# Needed mostly on Windows to export symbols, and create a .lib file, otherwise the binding
# library can't link to the sample library.
# target_compile_definitions(${sample_library} PRIVATE BINDINGS_BUILD)


# ====================== Shiboken target for generating binding C++ files  ====================
get_target_property(qtcore_M_QT5_INCLUDES Qt5::Core INTERFACE_INCLUDE_DIRECTORIES)
set(qtcore_M_QT5_INCLUDES ${Qt5Core_INCLUDE_DIRS})

list(JOIN qtcore_M_QT5_INCLUDES ";-I" M_QT5_INCLUDES)

message(STATUS "${M_QT5_INCLUDES}")
set(M_QT5_INCLUDES ${M_QT5_INCLUDES})

message(STATUS "${Qt5Core_INCLUDE_DIRS}")
message(STATUS "${Qt5Core_LIBRARIES}")

# Set up the options to pass to shiboken.
set(shiboken_options --generator-set=shiboken --enable-parent-ctor-heuristic
    --enable-return-value-heuristic --use-isnull-as-nb_nonzero
    --avoid-protected-hack
    -I${CMAKE_CURRENT_SOURCE_DIR}
    -I${foo_source_dir}
    -I${M_QT5_INCLUDES}
    -T${CMAKE_CURRENT_SOURCE_DIR}
    -T${PYSIDE2_DIR}/typesystems/
    --output-directory=${CMAKE_CURRENT_BINARY_DIR}
    )

set(generated_sources_dependencies ${wrapped_header} ${typesystem_file})

# Add custom target to run shiboken to generate the binding cpp files.
add_custom_command(OUTPUT ${generated_sources}
                    COMMAND ${shiboken_path}
                    ${shiboken_options} ${wrapped_header} ${typesystem_file}
                    DEPENDS ${generated_sources_dependencies}
                    IMPLICIT_DEPENDS CXX ${wrapped_header}
                    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                    COMMENT "Running generator for ${typesystem_file}.")


# =============================== CMake target - bindings_library =============================


# Set the cpp files which will be used for the bindings library.
set(${bindings_library}_sources ${generated_sources})

# Define and build the bindings library.
add_library(${bindings_library} MODULE ${${bindings_library}_sources})


# Apply relevant include and link flags.
target_include_directories(${bindings_library} PRIVATE ${python_include_dir})
target_include_directories(${bindings_library} PRIVATE ${shiboken_include_dir})
target_include_directories(${bindings_library} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

target_include_directories(${bindings_library} PRIVATE ${PYSIDE2_DIR}/include/)
target_include_directories(${bindings_library} PRIVATE ${PYSIDE2_DIR}/include/QtCore)
# target_include_directories(${bindings_library} PRIVATE ${qt5_include} ${qt5core_include})
target_include_directories(${bindings_library} PRIVATE "${Qt5Core_INCLUDE_DIRS}")
target_include_directories(${bindings_library} PRIVATE ${foo_source_dir})

message(STATUS "${shiboken_shared_libraries}")
target_link_libraries(${bindings_library} PRIVATE ${shiboken_shared_libraries})
target_link_libraries(${bindings_library} PRIVATE ${foo_lib_dir}/${sample_library})

# Adjust the name of generated module.
set_property(TARGET ${bindings_library} PROPERTY PREFIX "")
set_property(TARGET ${bindings_library} PROPERTY OUTPUT_NAME
             "${bindings_library}${PYTHON_EXTENSION_SUFFIX}")
if(WIN32)
    set_property(TARGET ${bindings_library} PROPERTY SUFFIX ".pyd")
endif()

# Make sure the linker doesn't complain about not finding Python symbols on macOS.
if(APPLE)
  set_target_properties(${bindings_library} PROPERTIES LINK_FLAGS "-undefined dynamic_lookup")
endif(APPLE)

# Find and link to the python import library only on Windows.
# On Linux and macOS, the undefined symbols will get resolved by the dynamic linker
# (the symbols will be picked up in the Python executable).
if (WIN32)
    list(GET python_linking_data 0 python_libdir)
    list(GET python_linking_data 1 python_lib)
    find_library(python_link_flags ${python_lib} PATHS ${python_libdir} HINTS ${python_libdir})
    target_link_libraries(${bindings_library} PRIVATE ${python_link_flags})
endif()


# ================================= Dubious deployment section ================================


if(WIN32)
    # =========================================================================================
    # !!! (The section below is deployment related, so in a real world application you will
    # want to take care of this properly (this is simply to eliminate errors that users usually
    # encounter.
    # =========================================================================================
    # Circumvent some "#pragma comment(lib)"s in "include/pyconfig.h" which might force to link
    # against a wrong python shared library.

    set(python_versions_list 3 32 33 34 35 36 37 38)
    set(python_additional_link_flags "")
    foreach(ver ${python_versions_list})
        set(python_additional_link_flags
            "${python_additional_link_flags} /NODEFAULTLIB:\"python${ver}_d.lib\"")
        set(python_additional_link_flags
            "${python_additional_link_flags} /NODEFAULTLIB:\"python${ver}.lib\"")
    endforeach()

    set_target_properties(${bindings_library}
                           PROPERTIES LINK_FLAGS "${python_additional_link_flags}")

    # Add custom target to hard-link shiboken shared libraries into the build folder, so that
    # the user doesn't have to set the PATH manually to point to the PySide2 package.
    foreach(library_path ${shiboken_shared_libraries})
        string(REGEX REPLACE ".lib$" ".dll" library_path ${library_path})
        get_filename_component(base_name ${library_path} NAME)
        file(TO_NATIVE_PATH ${library_path} source_path)
        file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/${base_name}" dest_path)
        add_custom_command(OUTPUT "${base_name}"
                            COMMAND mklink /H "${dest_path}" "${source_path}"
                            DEPENDS ${library_path}
                            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                            COMMENT "Creating hardlink to shiboken shared library ${base_name}")

        # Fake target that depends on the previous one, but has special ALL keyword, which means
        # it will always be executed.
        add_custom_target("fake_${base_name}" ALL DEPENDS ${base_name})
    endforeach()
    # =========================================================================================
    # !!! End of dubious section.
    # =========================================================================================
endif()

# =============================================================================================
# !!! (The section below is deployment related, so in a real world application you will want to
# take care of this properly with some custom script or tool).
# =============================================================================================
# Install the library and the bindings module into the source folder near the main.py file, so
# that the Python interpeter successfully imports the used module.
# install(TARGETS ${bindings_library} ${sample_library}
#         LIBRARY DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}
#         RUNTIME DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}
#         )
install(TARGETS ${bindings_library}
        LIBRARY DESTINATION ${foo_lib_dir}
        RUNTIME DESTINATION ${foo_lib_dir}
        )
# =============================================================================================
# !!! End of dubious section.
# =============================================================================================
