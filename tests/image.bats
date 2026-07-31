#!/usr/bin/env bats
# Image command tests

load 'test_helper'

# Skip all tests if imagemagick is not installed
setup() {
    if ! command -v convert &> /dev/null; then
        skip "imagemagick not installed"
    fi
    TEST_TMP="$(mktemp -d)"
    export TEST_TMP
    create_test_fixtures
}

# =============================================================================
# image convert - basics
# =============================================================================

@test "image convert shows help without arguments" {
    run_lazy image convert
    assert_output_contains "Usage: lazy image convert"
    [ "$status" -eq 1 ]
}

@test "image convert warns on nonexistent file" {
    run_lazy image convert "${TEST_TMP}/nonexistent.png" "${TEST_TMP}/test_image.png"
    assert_output_contains "File not found"
    assert_output_contains "Converted: 1"
    assert_output_contains "Skipped: 1"
    [ "$status" -eq 0 ]
}

@test "image convert fails when nothing could be converted" {
    run_lazy image convert "${TEST_TMP}/nonexistent.png"
    assert_output_contains "File not found"
    assert_output_contains "Converted: 0"
    [ "$status" -eq 1 ]
}

@test "image convert converts single file with default name" {
    run_lazy image convert "${TEST_TMP}/test_image.png"
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_image_q85.jpg"
}

@test "image convert converts multiple files" {
    run_lazy image convert "${TEST_TMP}/test_image.png" "${TEST_TMP}/test_image2.png"
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_image_q85.jpg"
    assert_file_exists "${TEST_TMP}/test_image2_q85.jpg"
    assert_output_contains "Converted: 2"
}

@test "image convert with format option" {
    run_lazy image convert "${TEST_TMP}/test_image.png" -f webp
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_image_q85.webp"
}

@test "image convert with quality option" {
    run_lazy image convert "${TEST_TMP}/test_image.png" -q 70
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_image_q70.jpg"
}

@test "image convert to grayscale" {
    run_lazy image convert "${TEST_TMP}/test_image.png" -g
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_image_q85_gray.jpg"
    is_grayscale "${TEST_TMP}/test_image_q85_gray.jpg"
}

@test "image convert accepts long options" {
    run_lazy image convert "${TEST_TMP}/test_image.png" --format png --quality 90 --gray
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_image_q90_gray.png"
}

# =============================================================================
# image convert - explicit output (-o)
# =============================================================================

@test "image convert with explicit output" {
    run_lazy image convert "${TEST_TMP}/test_image.png" -o "${TEST_TMP}/custom.jpg"
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/custom.jpg"
}

@test "image convert -o with multiple inputs fails" {
    run_lazy image convert "${TEST_TMP}/test_image.png" "${TEST_TMP}/test_image2.png" -o "${TEST_TMP}/custom.jpg"
    assert_output_contains "only supported with a single input"
    [ "$status" -eq 1 ]
}

# =============================================================================
# image convert - resize (percentage and exact pixels)
# =============================================================================

@test "image convert resize by percentage" {
    run_lazy image convert "${TEST_TMP}/test_image.png" -r 50
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_image_q85_r50.jpg"
    [ "$(get_image_dimensions "${TEST_TMP}/test_image_q85_r50.jpg")" = "50x50" ]
}

@test "image convert resize by width maintains aspect ratio" {
    run_lazy image convert "${TEST_TMP}/test_landscape.png" -w 100
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_landscape_q85_w100.jpg"
    [ "$(get_image_dimensions "${TEST_TMP}/test_landscape_q85_w100.jpg")" = "100x50" ]
}

@test "image convert resize by height maintains aspect ratio" {
    run_lazy image convert "${TEST_TMP}/test_image.png" -h 50
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_image_q85_h50.jpg"
    [ "$(get_image_dimensions "${TEST_TMP}/test_image_q85_h50.jpg")" = "50x50" ]
}

@test "image convert resize by exact size" {
    run_lazy image convert "${TEST_TMP}/test_image.png" -s 80x60
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_image_q85_80x60.jpg"
    [ "$(get_image_dimensions "${TEST_TMP}/test_image_q85_80x60.jpg")" = "80x60" ]
}

@test "image convert rejects combining -r with -w" {
    run_lazy image convert "${TEST_TMP}/test_image.png" -r 50 -w 80
    assert_output_contains "Cannot combine"
    [ "$status" -eq 1 ]
}

# =============================================================================
# image convert - non-conflicting output naming (macOS convention)
# =============================================================================

@test "image convert never overwrites, appends a number" {
    run_lazy image convert "${TEST_TMP}/test_image.png"
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_image_q85.jpg"

    # Second run must not prompt and must not clobber the first output.
    run_lazy image convert "${TEST_TMP}/test_image.png"
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_image_q85.jpg"
    assert_file_exists "${TEST_TMP}/test_image_q85 2.jpg"
}

# =============================================================================
# image - removed/unknown subcommands
# =============================================================================

@test "image unknown subcommand fails" {
    run_lazy image unknownsub
    assert_output_contains "Unknown command: image unknownsub"
    [ "$status" -eq 1 ]
}

@test "image resize is no longer a subcommand" {
    run_lazy image resize "${TEST_TMP}/test_image.png" -w 50
    assert_output_contains "Unknown command: image resize"
    [ "$status" -eq 1 ]
}

@test "image batch_convert is no longer a subcommand" {
    run_lazy image batch_convert "${TEST_TMP}/test_image.png"
    assert_output_contains "Unknown command: image batch_convert"
    [ "$status" -eq 1 ]
}
