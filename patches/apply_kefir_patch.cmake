# KEFIR: Apply a unified-diff patch to a FetchContent source directory in an
# idempotent way. CMake re-configures may invoke PATCH_COMMAND more than once
# (e.g. when the stamp is invalidated but the source tree is already patched),
# so we first ask `git apply --reverse --check` whether the patch is already
# applied; if so we no-op, otherwise we apply it.
#
# Required cache variables:
#   KEFIR_PATCH - absolute path to the .patch file (unified diff with a/ b/ prefixes)
#   KEFIR_SRC   - absolute path to the source directory to patch

if(NOT KEFIR_PATCH OR NOT KEFIR_SRC)
    message(FATAL_ERROR "apply_kefir_patch.cmake: KEFIR_PATCH and KEFIR_SRC must be set")
endif()

if(NOT EXISTS "${KEFIR_PATCH}")
    message(FATAL_ERROR "apply_kefir_patch.cmake: patch file does not exist: ${KEFIR_PATCH}")
endif()

if(NOT IS_DIRECTORY "${KEFIR_SRC}")
    message(FATAL_ERROR "apply_kefir_patch.cmake: source directory does not exist: ${KEFIR_SRC}")
endif()

find_program(GIT_EXECUTABLE git REQUIRED)

# Check if the patch is already applied (reverse-apply check exits 0 iff the
# patch's "new" state is already present).
execute_process(
    COMMAND "${GIT_EXECUTABLE}" -C "${KEFIR_SRC}" apply --reverse --check "${KEFIR_PATCH}"
    RESULT_VARIABLE _reverse_check_rc
    OUTPUT_QUIET
    ERROR_QUIET
)

if(_reverse_check_rc EQUAL 0)
    message(STATUS "KEFIR: ${KEFIR_PATCH} already applied to ${KEFIR_SRC}, skipping")
    return()
endif()

# Otherwise apply it. Use --whitespace=fix so trivial EOL differences from a
# fresh git clone don't abort the apply.
execute_process(
    COMMAND "${GIT_EXECUTABLE}" -C "${KEFIR_SRC}" apply --whitespace=fix "${KEFIR_PATCH}"
    RESULT_VARIABLE _apply_rc
)

if(NOT _apply_rc EQUAL 0)
    message(FATAL_ERROR "apply_kefir_patch.cmake: failed to apply ${KEFIR_PATCH} to ${KEFIR_SRC}")
endif()

message(STATUS "KEFIR: applied ${KEFIR_PATCH} to ${KEFIR_SRC}")
