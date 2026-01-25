#!/usr/bin/env bats
# Video command tests

load 'test_helper'

# Skip all tests if ffmpeg is not installed
setup() {
    if ! command -v ffmpeg &> /dev/null; then
        skip "ffmpeg not installed"
    fi
    TEST_TMP="$(mktemp -d)"
    export TEST_TMP
    create_test_fixtures
}

# =============================================================================
# video convert tests
# =============================================================================

@test "video convert shows help without arguments" {
    run_lazy video convert
    assert_output_contains "Usage: lazy video convert"
    [ "$status" -eq 1 ]
}

@test "video convert with nonexistent file warns and continues" {
    run_lazy video convert "${TEST_TMP}/nonexistent.mov"
    assert_output_contains "File not found"
    [ "$status" -eq 0 ]
}

@test "video convert creates mp4 file" {
    run_lazy video convert "${TEST_TMP}/test_video.mp4" -q ultrafast
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_video_converted.mp4"
}

@test "video convert with quality option fast" {
    # Create a second test video
    cp "${TEST_TMP}/test_video.mp4" "${TEST_TMP}/test_fast.mp4"
    run_lazy video convert "${TEST_TMP}/test_fast.mp4" -q fast
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_fast_converted.mp4"
}

@test "video convert accepts long quality option" {
    cp "${TEST_TMP}/test_video.mp4" "${TEST_TMP}/test_long.mp4"
    run_lazy video convert "${TEST_TMP}/test_long.mp4" --quality ultrafast
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_long_converted.mp4"
}

@test "video convert multiple files" {
    cp "${TEST_TMP}/test_video.mp4" "${TEST_TMP}/test_video2.mp4"
    cp "${TEST_TMP}/test_video.mp4" "${TEST_TMP}/test_video3.mp4"
    run_lazy video convert "${TEST_TMP}/test_video2.mp4" "${TEST_TMP}/test_video3.mp4" -q ultrafast
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_video2_converted.mp4"
    assert_file_exists "${TEST_TMP}/test_video3_converted.mp4"
    assert_output_contains "Converted: 2"
}

@test "video convert skips existing output files" {
    cp "${TEST_TMP}/test_video.mp4" "${TEST_TMP}/test_skip.mp4"
    # Create output file first
    touch "${TEST_TMP}/test_skip_converted.mp4"
    run_lazy video convert "${TEST_TMP}/test_skip.mp4" -q ultrafast
    assert_output_contains "Skipping"
    assert_output_contains "output exists"
    [ "$status" -eq 0 ]
}

@test "video convert scales down large video to 720p landscape" {
    # Create a 1920x1080 test video
    ffmpeg -f lavfi -i testsrc=duration=1:size=1920x1080:rate=10 \
        -c:v libx264 -pix_fmt yuv420p \
        "${TEST_TMP}/large_landscape.mp4" -y 2>/dev/null

    run_lazy video convert "${TEST_TMP}/large_landscape.mp4" -q ultrafast
    [ "$status" -eq 0 ]

    local dims
    dims=$(get_video_dimensions "${TEST_TMP}/large_landscape_converted.mp4")
    [ "$dims" = "1280x720" ]
}

@test "video convert scales down large video to 720p portrait" {
    # Create a 1080x1920 test video (portrait)
    ffmpeg -f lavfi -i testsrc=duration=1:size=1080x1920:rate=10 \
        -c:v libx264 -pix_fmt yuv420p \
        "${TEST_TMP}/large_portrait.mp4" -y 2>/dev/null

    run_lazy video convert "${TEST_TMP}/large_portrait.mp4" -q ultrafast
    [ "$status" -eq 0 ]

    local dims
    dims=$(get_video_dimensions "${TEST_TMP}/large_portrait_converted.mp4")
    [ "$dims" = "720x1280" ]
}

@test "video convert keeps small video dimensions" {
    # The test video is 320x240, should stay the same (under 720p)
    run_lazy video convert "${TEST_TMP}/test_video.mp4" -q ultrafast
    [ "$status" -eq 0 ]

    local dims
    dims=$(get_video_dimensions "${TEST_TMP}/test_video_converted.mp4")
    # Dimensions should be divisible by 2, original is 320x240
    [ "$dims" = "320x240" ]
}

@test "video convert ensures dimensions divisible by 2" {
    # Create a video with dimensions that need rounding (use rawvideo to allow odd sizes)
    ffmpeg -f lavfi -i "color=c=red:s=321x241:d=1:r=10" \
        -c:v rawvideo -pix_fmt rgb24 \
        "${TEST_TMP}/odd_dims.avi" -y 2>/dev/null

    run_lazy video convert "${TEST_TMP}/odd_dims.avi" -q ultrafast
    [ "$status" -eq 0 ]

    local dims
    dims=$(get_video_dimensions "${TEST_TMP}/odd_dims.mp4")
    local width height
    width=$(echo "$dims" | cut -d'x' -f1)
    height=$(echo "$dims" | cut -d'x' -f2)

    # Both dimensions should be even (divisible by 2)
    [ $((width % 2)) -eq 0 ]
    [ $((height % 2)) -eq 0 ]
}

@test "video convert shows file size comparison" {
    cp "${TEST_TMP}/test_video.mp4" "${TEST_TMP}/test_size.mp4"
    run_lazy video convert "${TEST_TMP}/test_size.mp4" -q ultrafast
    [ "$status" -eq 0 ]
    # Output should contain arrow showing size conversion
    assert_output_contains "->"
}

# =============================================================================
# video unknown subcommand
# =============================================================================

@test "video unknown subcommand fails" {
    run_lazy video unknownsub
    assert_output_contains "Unknown command: video unknownsub"
    [ "$status" -eq 1 ]
}
