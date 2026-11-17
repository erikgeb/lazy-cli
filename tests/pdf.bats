#!/usr/bin/env bats
# PDF command tests

load 'test_helper'

# Skip all tests if ghostscript is not installed
setup() {
    if ! command -v gs &> /dev/null; then
        skip "ghostscript not installed"
    fi
    # Call parent setup
    TEST_TMP="$(mktemp -d)"
    export TEST_TMP
    create_test_fixtures
}

# =============================================================================
# pdf compress tests
# =============================================================================

@test "pdf compress shows help without arguments" {
    run_lazy pdf compress
    assert_output_contains "Usage: lazy pdf compress"
    [ "$status" -eq 1 ]
}

@test "pdf compress with nonexistent file fails" {
    run_lazy pdf compress "${TEST_TMP}/nonexistent.pdf"
    assert_output_contains "File not found"
    [ "$status" -eq 1 ]
}

@test "pdf compress creates compressed file with default name" {
    run_lazy pdf compress "${TEST_TMP}/test.pdf"
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_compressed.pdf"
}

@test "pdf compress creates file with custom output name" {
    run_lazy pdf compress "${TEST_TMP}/test.pdf" -o "${TEST_TMP}/output.pdf"
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/output.pdf"
}

@test "pdf compress accepts quality option screen" {
    run_lazy pdf compress "${TEST_TMP}/test.pdf" -q screen -o "${TEST_TMP}/screen.pdf"
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/screen.pdf"
}

@test "pdf compress accepts quality option ebook" {
    run_lazy pdf compress "${TEST_TMP}/test.pdf" -q ebook -o "${TEST_TMP}/ebook.pdf"
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/ebook.pdf"
}

@test "pdf compress accepts quality option printer" {
    run_lazy pdf compress "${TEST_TMP}/test.pdf" -q printer -o "${TEST_TMP}/printer.pdf"
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/printer.pdf"
}

@test "pdf compress accepts quality option prepress" {
    run_lazy pdf compress "${TEST_TMP}/test.pdf" -q prepress -o "${TEST_TMP}/prepress.pdf"
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/prepress.pdf"
}

@test "pdf compress accepts --quality long option" {
    run_lazy pdf compress "${TEST_TMP}/test.pdf" --quality ebook -o "${TEST_TMP}/long.pdf"
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/long.pdf"
}

@test "pdf compress accepts --output long option" {
    run_lazy pdf compress "${TEST_TMP}/test.pdf" --output "${TEST_TMP}/longout.pdf"
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/longout.pdf"
}

@test "pdf compress does not overwrite; writes a numbered file instead" {
    # Pre-existing output must be left untouched; a numbered variant is created.
    touch "${TEST_TMP}/existing.pdf"
    run_lazy pdf compress "${TEST_TMP}/test.pdf" -o "${TEST_TMP}/existing.pdf"
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/existing 2.pdf"
}

# =============================================================================
# pdf merge tests
# =============================================================================

@test "pdf merge shows help without enough arguments" {
    run_lazy pdf merge "${TEST_TMP}/test.pdf"
    assert_output_contains "Usage: lazy pdf merge"
    [ "$status" -eq 1 ]
}

@test "pdf merge requires output option" {
    run_lazy pdf merge "${TEST_TMP}/test.pdf" "${TEST_TMP}/test2.pdf"
    assert_output_contains "Output file required"
    [ "$status" -eq 1 ]
}

@test "pdf merge creates merged file" {
    run_lazy pdf merge "${TEST_TMP}/test.pdf" "${TEST_TMP}/test2.pdf" -o "${TEST_TMP}/merged.pdf"
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/merged.pdf"
}

@test "pdf merge accepts --output long option" {
    run_lazy pdf merge "${TEST_TMP}/test.pdf" "${TEST_TMP}/test2.pdf" --output "${TEST_TMP}/merged2.pdf"
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/merged2.pdf"
}

@test "pdf merge does not overwrite; writes a numbered file instead" {
    touch "${TEST_TMP}/existing_merge.pdf"
    run_lazy pdf merge "${TEST_TMP}/test.pdf" "${TEST_TMP}/test2.pdf" -o "${TEST_TMP}/existing_merge.pdf"
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/existing_merge 2.pdf"
}

# =============================================================================
# pdf rotate tests
# =============================================================================

@test "pdf rotate shows help without arguments" {
    run_lazy pdf rotate
    assert_output_contains "Usage: lazy pdf rotate"
    [ "$status" -eq 1 ]
}

@test "pdf rotate with nonexistent file fails" {
    run_lazy pdf rotate "${TEST_TMP}/nonexistent.pdf"
    assert_output_contains "File not found"
    [ "$status" -eq 1 ]
}

@test "pdf rotate rotates single file 90 degrees clockwise with default name" {
    if ! command -v qpdf &> /dev/null; then
        skip "qpdf not installed"
    fi
    run_lazy pdf rotate "${TEST_TMP}/test.pdf"
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_rotated.pdf"
    if command -v pdfinfo &> /dev/null; then
        [ "$(get_pdf_page_rotation "${TEST_TMP}/test_rotated.pdf")" = "90" ]
    fi
}

@test "pdf rotate accumulates 90 degrees clockwise on successive rotations" {
    if ! command -v qpdf &> /dev/null; then
        skip "qpdf not installed"
    fi
    run_lazy pdf rotate "${TEST_TMP}/test.pdf" -o "${TEST_TMP}/step1.pdf"
    [ "$status" -eq 0 ]
    run_lazy pdf rotate "${TEST_TMP}/step1.pdf" -o "${TEST_TMP}/step2.pdf"
    [ "$status" -eq 0 ]
    if command -v pdfinfo &> /dev/null; then
        [ "$(get_pdf_page_rotation "${TEST_TMP}/step1.pdf")" = "90" ]
        [ "$(get_pdf_page_rotation "${TEST_TMP}/step2.pdf")" = "180" ]
    fi
}

@test "pdf rotate creates file with custom output name" {
    if ! command -v qpdf &> /dev/null; then
        skip "qpdf not installed"
    fi
    run_lazy pdf rotate "${TEST_TMP}/test.pdf" -o "${TEST_TMP}/custom_rot.pdf"
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/custom_rot.pdf"
    if command -v pdfinfo &> /dev/null; then
        [ "$(get_pdf_page_rotation "${TEST_TMP}/custom_rot.pdf")" = "90" ]
    fi
}

@test "pdf rotate accepts --output long option" {
    if ! command -v qpdf &> /dev/null; then
        skip "qpdf not installed"
    fi
    run_lazy pdf rotate "${TEST_TMP}/test.pdf" --output "${TEST_TMP}/long_rot.pdf"
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/long_rot.pdf"
}

@test "pdf rotate does not overwrite; writes a numbered file instead" {
    if ! command -v qpdf &> /dev/null; then
        skip "qpdf not installed"
    fi
    touch "${TEST_TMP}/existing_rot.pdf"
    run_lazy pdf rotate "${TEST_TMP}/test.pdf" -o "${TEST_TMP}/existing_rot.pdf"
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/existing_rot 2.pdf"
}

@test "pdf rotate accepts explicit degrees (-d 180 and -d 270)" {
    if ! command -v qpdf &> /dev/null; then
        skip "qpdf not installed"
    fi
    run_lazy pdf rotate "${TEST_TMP}/test.pdf" -d 180 -o "${TEST_TMP}/rot180.pdf"
    [ "$status" -eq 0 ]
    run_lazy pdf rotate "${TEST_TMP}/test.pdf" --degrees 270 -o "${TEST_TMP}/rot270.pdf"
    [ "$status" -eq 0 ]
    if command -v pdfinfo &> /dev/null; then
        [ "$(get_pdf_page_rotation "${TEST_TMP}/rot180.pdf")" = "180" ]
        [ "$(get_pdf_page_rotation "${TEST_TMP}/rot270.pdf")" = "270" ]
    fi
}

@test "pdf rotate rejects invalid degrees" {
    run_lazy pdf rotate "${TEST_TMP}/test.pdf" -d 45
    assert_output_contains "Invalid degrees"
    [ "$status" -eq 1 ]
}

@test "pdf rotate rejects -o with multiple inputs" {
    run_lazy pdf rotate "${TEST_TMP}/test.pdf" "${TEST_TMP}/test2.pdf" -o "${TEST_TMP}/out.pdf"
    assert_output_contains "-o/--output is only supported with a single input file"
    [ "$status" -eq 1 ]
}

@test "pdf rotate rotates multiple files" {
    if ! command -v qpdf &> /dev/null; then
        skip "qpdf not installed"
    fi
    run_lazy pdf rotate "${TEST_TMP}/test.pdf" "${TEST_TMP}/test2.pdf"
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_rotated.pdf"
    assert_file_exists "${TEST_TMP}/test2_rotated.pdf"
}

@test "pdf rotate preserves content stream and text (metadata only)" {
    if ! command -v qpdf &> /dev/null; then
        skip "qpdf not installed"
    fi
    run_lazy pdf rotate "${TEST_TMP}/test_vtext.pdf" -o "${TEST_TMP}/rotated_vtext.pdf"
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/rotated_vtext.pdf"
    if command -v pdfinfo &> /dev/null; then
        [ "$(get_pdf_page_rotation "${TEST_TMP}/rotated_vtext.pdf")" = "90" ]
    fi
    if command -v pdftotext &> /dev/null; then
        local text
        text=$(pdftotext "${TEST_TMP}/rotated_vtext.pdf" -)
        [[ "$text" == *"Hello Vertical World"* ]]
    fi
}

# =============================================================================
# pdf unknown subcommand
# =============================================================================

@test "pdf unknown subcommand fails" {
    run_lazy pdf unknownsub
    assert_output_contains "Unknown command: pdf unknownsub"
    [ "$status" -eq 1 ]
}

# =============================================================================
# pdf orientation preservation
# =============================================================================

@test "pdf compress preserves page orientation (no auto-rotation)" {
    if ! command -v pdfinfo &> /dev/null; then
        skip "pdfinfo not installed"
    fi
    run_lazy pdf compress "${TEST_TMP}/test_vtext.pdf" -o "${TEST_TMP}/compressed_vtext.pdf"
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/compressed_vtext.pdf"
    [ "$(get_pdf_page_rotation "${TEST_TMP}/compressed_vtext.pdf")" = "0" ]
}

@test "pdf merge preserves page orientation (no auto-rotation)" {
    if ! command -v pdfinfo &> /dev/null; then
        skip "pdfinfo not installed"
    fi
    run_lazy pdf merge "${TEST_TMP}/test_vtext.pdf" "${TEST_TMP}/test_vtext2.pdf" -o "${TEST_TMP}/merged_vtext.pdf"
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/merged_vtext.pdf"
    [ "$(get_pdf_page_rotation "${TEST_TMP}/merged_vtext.pdf")" = "0" ]
}
