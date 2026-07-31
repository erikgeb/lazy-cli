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

# Helper: report the video codec of a file's first video stream
get_video_codec() {
    ffprobe -v error -select_streams v:0 -show_entries stream=codec_name \
        -of csv=p=0 "$1"
}

# Helper: report the audio codec of a file's first audio stream (empty if none)
get_audio_codec() {
    ffprobe -v error -select_streams a:0 -show_entries stream=codec_name \
        -of csv=p=0 "$1"
}

# =============================================================================
# video convert - basics
# =============================================================================

@test "video convert shows help without arguments" {
    run_lazy video convert
    assert_output_contains "Usage: lazy video convert"
    [ "$status" -eq 1 ]
}

@test "video convert fails when nothing could be converted" {
    run_lazy video convert "${TEST_TMP}/nonexistent.mov"
    assert_output_contains "File not found"
    assert_output_contains "Converted: 0"
    [ "$status" -eq 1 ]
}

@test "video convert creates _h265.mp4 file by default" {
    run_lazy video convert "${TEST_TMP}/test_video.mp4" -m small
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_video_h265.mp4"
}

@test "video convert defaults to the h265/hevc codec" {
    run_lazy video convert "${TEST_TMP}/test_video.mp4" -m small
    [ "$status" -eq 0 ]
    [ "$(get_video_codec "${TEST_TMP}/test_video_h265.mp4")" = "hevc" ]
}

@test "video convert multiple files" {
    cp "${TEST_TMP}/test_video.mp4" "${TEST_TMP}/test_video2.mp4"
    cp "${TEST_TMP}/test_video.mp4" "${TEST_TMP}/test_video3.mp4"
    run_lazy video convert "${TEST_TMP}/test_video2.mp4" "${TEST_TMP}/test_video3.mp4" -m small
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_video2_h265.mp4"
    assert_file_exists "${TEST_TMP}/test_video3_h265.mp4"
    assert_output_contains "Converted: 2"
}

@test "video convert shows file size comparison" {
    run_lazy video convert "${TEST_TMP}/test_video.mp4" -m small
    [ "$status" -eq 0 ]
    assert_output_contains "->"
}

# =============================================================================
# video convert - codec selection
# =============================================================================

@test "video convert to h264 names output _h264 and uses the h264 codec" {
    run_lazy video convert "${TEST_TMP}/test_video.mp4" -c h264 -m small
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_video_h264.mp4"
    [ "$(get_video_codec "${TEST_TMP}/test_video_h264.mp4")" = "h264" ]
}

@test "video convert rejects unknown codec" {
    run_lazy video convert "${TEST_TMP}/test_video.mp4" -c av1
    assert_output_contains "Unknown codec: av1"
    [ "$status" -eq 1 ]
}

# =============================================================================
# video convert - modes
# =============================================================================

@test "video convert quality mode via long option" {
    run_lazy video convert "${TEST_TMP}/test_video.mp4" --mode quality
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_video_h265.mp4"
}

@test "video convert rejects unknown mode" {
    run_lazy video convert "${TEST_TMP}/test_video.mp4" -m bogus
    assert_output_contains "Unknown mode: bogus"
    [ "$status" -eq 1 ]
}

# =============================================================================
# video convert - resolution
# =============================================================================

@test "video convert keeps original resolution by default (input)" {
    ffmpeg -f lavfi -i testsrc=duration=1:size=1920x1080:rate=10 \
        -c:v libx264 -pix_fmt yuv420p \
        "${TEST_TMP}/keep_res.mp4" -y 2>/dev/null

    run_lazy video convert "${TEST_TMP}/keep_res.mp4" -m small
    [ "$status" -eq 0 ]
    [ "$(get_video_dimensions "${TEST_TMP}/keep_res_h265.mp4")" = "1920x1080" ]
}

@test "video convert scales down landscape to 720p" {
    ffmpeg -f lavfi -i testsrc=duration=1:size=1920x1080:rate=10 \
        -c:v libx264 -pix_fmt yuv420p \
        "${TEST_TMP}/large_landscape.mp4" -y 2>/dev/null

    run_lazy video convert "${TEST_TMP}/large_landscape.mp4" -m small -r 720p
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/large_landscape_h265_720p.mp4"
    [ "$(get_video_dimensions "${TEST_TMP}/large_landscape_h265_720p.mp4")" = "1280x720" ]
}

@test "video convert scales down portrait to 720p (orientation-aware)" {
    ffmpeg -f lavfi -i testsrc=duration=1:size=1080x1920:rate=10 \
        -c:v libx264 -pix_fmt yuv420p \
        "${TEST_TMP}/large_portrait.mp4" -y 2>/dev/null

    run_lazy video convert "${TEST_TMP}/large_portrait.mp4" -m small -r 720p
    [ "$status" -eq 0 ]
    [ "$(get_video_dimensions "${TEST_TMP}/large_portrait_h265_720p.mp4")" = "720x1280" ]
}

@test "video convert scales down to 1080p" {
    ffmpeg -f lavfi -i testsrc=duration=1:size=3840x2160:rate=10 \
        -c:v libx264 -pix_fmt yuv420p \
        "${TEST_TMP}/uhd.mp4" -y 2>/dev/null

    run_lazy video convert "${TEST_TMP}/uhd.mp4" -m small -r 1080p
    [ "$status" -eq 0 ]
    [ "$(get_video_dimensions "${TEST_TMP}/uhd_h265_1080p.mp4")" = "1920x1080" ]
}

@test "video convert does not upscale below the cap" {
    # 320x240 is well under 1080p; it must stay 320x240, not grow.
    run_lazy video convert "${TEST_TMP}/test_video.mp4" -m small -r 1080p
    [ "$status" -eq 0 ]
    [ "$(get_video_dimensions "${TEST_TMP}/test_video_h265_1080p.mp4")" = "320x240" ]
}

@test "video convert rejects unknown resolution" {
    run_lazy video convert "${TEST_TMP}/test_video.mp4" -r 480p
    assert_output_contains "Unknown resolution: 480p"
    [ "$status" -eq 1 ]
}

@test "video convert ensures dimensions divisible by 2" {
    ffmpeg -f lavfi -i "color=c=red:s=321x241:d=1:r=10" \
        -c:v rawvideo -pix_fmt rgb24 \
        "${TEST_TMP}/odd_dims.avi" -y 2>/dev/null

    run_lazy video convert "${TEST_TMP}/odd_dims.avi" -m small
    [ "$status" -eq 0 ]

    local dims width height
    dims=$(get_video_dimensions "${TEST_TMP}/odd_dims_h265.mp4")
    width=$(echo "$dims" | cut -d'x' -f1)
    height=$(echo "$dims" | cut -d'x' -f2)
    [ $((width % 2)) -eq 0 ]
    [ $((height % 2)) -eq 0 ]
}

# =============================================================================
# video convert - non-conflicting output naming
# =============================================================================

@test "video convert never overwrites, appends a number" {
    run_lazy video convert "${TEST_TMP}/test_video.mp4" -m small
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_video_h265.mp4"

    run_lazy video convert "${TEST_TMP}/test_video.mp4" -m small
    [ "$status" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_video_h265.mp4"
    assert_file_exists "${TEST_TMP}/test_video_h265 2.mp4"
}

# =============================================================================
# video convert - audio handling
# =============================================================================

@test "video convert copies MP4-safe audio by default (balanced)" {
    ffmpeg -f lavfi -i testsrc=duration=1:size=320x240:rate=10 \
        -f lavfi -i sine=frequency=440:duration=1 \
        -c:v libx264 -pix_fmt yuv420p -c:a libmp3lame -shortest \
        "${TEST_TMP}/with_mp3.mkv" -y 2>/dev/null

    run_lazy video convert "${TEST_TMP}/with_mp3.mkv"
    [ "$status" -eq 0 ]
    [ "$(get_audio_codec "${TEST_TMP}/with_mp3_h265.mp4")" = "mp3" ]
}

@test "video convert re-encodes audio to aac in small mode" {
    ffmpeg -f lavfi -i testsrc=duration=1:size=320x240:rate=10 \
        -f lavfi -i sine=frequency=440:duration=1 \
        -c:v libx264 -pix_fmt yuv420p -c:a libmp3lame -shortest \
        "${TEST_TMP}/small_mp3.mkv" -y 2>/dev/null

    run_lazy video convert "${TEST_TMP}/small_mp3.mkv" -m small
    [ "$status" -eq 0 ]
    [ "$(get_audio_codec "${TEST_TMP}/small_mp3_h265.mp4")" = "aac" ]
}

@test "video convert transcodes incompatible audio to aac with a warning" {
    ffmpeg -f lavfi -i testsrc=duration=1:size=320x240:rate=10 \
        -f lavfi -i sine=frequency=440:duration=1 \
        -c:v libx264 -pix_fmt yuv420p -c:a libopus -shortest \
        "${TEST_TMP}/with_opus.mkv" -y 2>/dev/null

    run_lazy video convert "${TEST_TMP}/with_opus.mkv"
    [ "$status" -eq 0 ]
    assert_output_contains "isn't MP4/QuickTime-safe"
    [ "$(get_audio_codec "${TEST_TMP}/with_opus_h265.mp4")" = "aac" ]
}

@test "video convert handles source with no audio stream" {
    run_lazy video convert "${TEST_TMP}/test_video.mp4" -m small
    [ "$status" -eq 0 ]
    [ -z "$(get_audio_codec "${TEST_TMP}/test_video_h265.mp4")" ]
}

# =============================================================================
# video - removed/unknown subcommands
# =============================================================================

@test "video unknown subcommand fails" {
    run_lazy video unknownsub
    assert_output_contains "Unknown command: video unknownsub"
    [ "$status" -eq 1 ]
}

@test "video compress is no longer a subcommand" {
    run_lazy video compress "${TEST_TMP}/test_video.mp4"
    assert_output_contains "Unknown command: video compress"
    [ "$status" -eq 1 ]
}
