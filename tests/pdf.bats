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
# pdf unknown subcommand
# =============================================================================

@test "pdf unknown subcommand fails" {
    run_lazy pdf unknownsub
    assert_output_contains "Unknown command: pdf unknownsub"
    [ "$status" -eq 1 ]
}
