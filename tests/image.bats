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
# image resize tests
# =============================================================================

@test "image resize shows help without arguments" {
    run_lazy image resize
    assert_output_contains "Usage: lazy image resize"
    [ "$status" -eq 1 ]
}

@test "image resize with nonexistent file fails" {
    run_lazy image resize "${TEST_TMP}/nonexistent.png" -w 50
    assert_output_contains "File not found"
    [ "$status" -eq 1 ]
}

@test "image resize requires dimension option" {
    run_lazy image resize "${TEST_TMP}/test_image.png"
    assert_output_contains "Specify -s, -w, or -h"
    [ "$status" -eq 1 ]
}

@test "image resize by width creates resized file" {
    run_lazy image resize "${TEST_TMP}/test_image.png" -w 50
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_image_resized.png"
    [ "$(get_image_dimensions "${TEST_TMP}/test_image_resized.png")" = "50x50" ]
}

@test "image resize by height creates resized file" {
    run_lazy image resize "${TEST_TMP}/test_image.png" -h 50
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_image_resized.png"
    [ "$(get_image_dimensions "${TEST_TMP}/test_image_resized.png")" = "50x50" ]
}

@test "image resize by exact size creates resized file" {
    run_lazy image resize "${TEST_TMP}/test_image.png" -s 80x60
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_image_resized.png"
    [ "$(get_image_dimensions "${TEST_TMP}/test_image_resized.png")" = "80x60" ]
}

@test "image resize with custom output name" {
    run_lazy image resize "${TEST_TMP}/test_image.png" -w 50 -o "${TEST_TMP}/custom.png"
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/custom.png"
}

@test "image resize accepts long options" {
    run_lazy image resize "${TEST_TMP}/test_image.png" --width 50 --output "${TEST_TMP}/long.png"
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/long.png"
}

@test "image resize maintains aspect ratio with width" {
    run_lazy image resize "${TEST_TMP}/test_landscape.png" -w 100 -o "${TEST_TMP}/aspect.png"
    [ "$status" -eq 0 ]
    [ "$(get_image_dimensions "${TEST_TMP}/aspect.png")" = "100x50" ]
}

# =============================================================================
# image convert tests
# =============================================================================

@test "image convert shows help without arguments" {
    run_lazy image convert
    assert_output_contains "Usage: lazy image convert"
    [ "$status" -eq 1 ]
}

@test "image convert requires output option" {
    run_lazy image convert "${TEST_TMP}/test_image.png"
    assert_output_contains "Output file required"
    [ "$status" -eq 1 ]
}

@test "image convert png to jpg" {
    run_lazy image convert "${TEST_TMP}/test_image.png" -o "${TEST_TMP}/converted.jpg"
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/converted.jpg"
}

@test "image convert with quality option" {
    run_lazy image convert "${TEST_TMP}/test_image.png" -o "${TEST_TMP}/quality.jpg" -q 80
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/quality.jpg"
}

@test "image convert to grayscale" {
    run_lazy image convert "${TEST_TMP}/test_image.png" -o "${TEST_TMP}/gray.jpg" -g
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/gray.jpg"
    is_grayscale "${TEST_TMP}/gray.jpg"
}

@test "image convert with grayscale and quality" {
    run_lazy image convert "${TEST_TMP}/test_image.png" -o "${TEST_TMP}/grayq.jpg" -g -q 90
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/grayq.jpg"
    is_grayscale "${TEST_TMP}/grayq.jpg"
}

@test "image convert accepts long options" {
    run_lazy image convert "${TEST_TMP}/test_image.png" --output "${TEST_TMP}/long.jpg" --gray --quality 85
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/long.jpg"
}

# =============================================================================
# image optimize tests
# =============================================================================

@test "image optimize shows help without arguments" {
    run_lazy image optimize
    assert_output_contains "Usage: lazy image optimize"
    [ "$status" -eq 1 ]
}

@test "image optimize creates optimized file with default name" {
    run_lazy image optimize "${TEST_TMP}/test_image.png"
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_image_optimized.png"
}

@test "image optimize with custom output" {
    run_lazy image optimize "${TEST_TMP}/test_image.png" -o "${TEST_TMP}/opt.png"
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/opt.png"
}

@test "image optimize with quality option" {
    run_lazy image optimize "${TEST_TMP}/test_image.png" -q 70 -o "${TEST_TMP}/optq.png"
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/optq.png"
}

# =============================================================================
# image batch_convert tests
# =============================================================================

@test "image batch_convert shows help without arguments" {
    run_lazy image batch_convert
    assert_output_contains "Usage: lazy image batch_convert"
    [ "$status" -eq 1 ]
}

@test "image batch_convert converts single file" {
    run_lazy image batch_convert "${TEST_TMP}/test_image.png"
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_image_q85.jpg"
}

@test "image batch_convert converts multiple files" {
    run_lazy image batch_convert "${TEST_TMP}/test_image.png" "${TEST_TMP}/test_image2.png"
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_image_q85.jpg"
    assert_file_exists "${TEST_TMP}/test_image2_q85.jpg"
    assert_output_contains "Converted: 2"
}

@test "image batch_convert with format option" {
    run_lazy image batch_convert "${TEST_TMP}/test_image.png" -f webp
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_image_q85.webp"
}

@test "image batch_convert with quality option" {
    run_lazy image batch_convert "${TEST_TMP}/test_image.png" -q 70
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_image_q70.jpg"
}

@test "image batch_convert with resize option" {
    run_lazy image batch_convert "${TEST_TMP}/test_image.png" -r 50
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_image_q85_r50.jpg"
    [ "$(get_image_dimensions "${TEST_TMP}/test_image_q85_r50.jpg")" = "50x50" ]
}

@test "image batch_convert with grayscale option" {
    run_lazy image batch_convert "${TEST_TMP}/test_image.png" -g
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_image_q85_gray.jpg"
    is_grayscale "${TEST_TMP}/test_image_q85_gray.jpg"
}

@test "image batch_convert with all options" {
    run_lazy image batch_convert "${TEST_TMP}/test_image.png" -f webp -q 70 -r 50 -g
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_image_q70_r50_gray.webp"
}

@test "image batch_convert skips existing output files" {
    # Create output file first
    touch "${TEST_TMP}/test_image_q85.jpg"
    run_lazy image batch_convert "${TEST_TMP}/test_image.png"
    assert_output_contains "Skipping"
    assert_output_contains "Skipped: 1"
    [ "$status" -eq 0 ]
}

@test "image batch_convert warns on nonexistent file" {
    run_lazy image batch_convert "${TEST_TMP}/nonexistent.png" "${TEST_TMP}/test_image.png"
    assert_output_contains "File not found"
    assert_output_contains "Converted: 1"
    assert_output_contains "Skipped: 1"
    [ "$status" -eq 0 ]
}

@test "image batch_convert accepts long options" {
    run_lazy image batch_convert "${TEST_TMP}/test_image.png" --format png --quality 90 --resize 75 --gray
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_image_q90_r75_gray.png"
}

# =============================================================================
# image unknown subcommand
# =============================================================================

@test "image unknown subcommand fails" {
    run_lazy image unknownsub
    assert_output_contains "Unknown command: image unknownsub"
    [ "$status" -eq 1 ]
}
