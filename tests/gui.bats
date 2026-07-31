#!/usr/bin/env bats
# GUI dispatcher (gui/lazy-gui) tests.
#
# The osascript dialogs can't be clicked in CI, so we source the dispatcher and
# replace its UI helpers with stubs that return canned answers from UI_ANSWERS.
# Everything else (arg building, running lazy, the before/after reveal diff) is
# exercised for real against fixtures.

load 'test_helper'

setup() {
    TEST_TMP="$(mktemp -d)"
    export TEST_TMP
    create_test_fixtures
}

# Source lazy-gui and swap the UI helpers for stubs. Answers are popped in order
# from a file (so they survive the command-substitution subshells the dispatcher
# uses); `open` and notifications become no-ops.
load_gui() {
    export LAZY_BIN="${BATS_TEST_DIRNAME}/../lazy"
    source "${BATS_TEST_DIRNAME}/../gui/lazy-gui"

    export UI_ANSWER_FILE="${TEST_TMP}/.answers"
    : > "$UI_ANSWER_FILE"
    ui_choose() { _ui_pop; }
    ui_prompt() { _ui_pop; return 0; }
    ui_notify() { :; }
    ui_error()  { echo "UI_ERROR: $*" >&2; }
    open()      { :; }
}

# Pop and print the first queued answer (empty when the queue is exhausted,
# which the dispatcher treats as a cancel).
_ui_pop() {
    local line rest
    line="$(head -1 "$UI_ANSWER_FILE")"
    rest="$(tail -n +2 "$UI_ANSWER_FILE")"
    printf '%s\n' "$rest" > "$UI_ANSWER_FILE"
    printf '%s' "$line"
}

# Queue the answers ui_choose/ui_prompt will return, in order.
set_answers() {
    printf '%s\n' "$@" > "$UI_ANSWER_FILE"
}

# =============================================================================
# image
# =============================================================================

@test "gui image: JPEG + quality + resize + grayscale builds the right convert" {
    command -v convert &> /dev/null || skip "imagemagick not installed"
    load_gui
    set_answers "JPEG" "High (best looking)" "50%" "Grayscale"
    ( do_image "${TEST_TMP}/test_image.png" )
    [ "$?" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_image_q90_r50_gray.jpg"
    [ "$(get_image_dimensions "${TEST_TMP}/test_image_q90_r50_gray.jpg")" = "50x50" ]
    is_grayscale "${TEST_TMP}/test_image_q90_r50_gray.jpg"
}

@test "gui image: PNG target skips the quality question" {
    command -v convert &> /dev/null || skip "imagemagick not installed"
    load_gui
    # No quality answer supplied; PNG must not consume one.
    set_answers "PNG" "Keep original size" "Keep colors"
    ( do_image "${TEST_TMP}/test_image.png" )
    [ "$?" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_image_q85.png"
}

@test "gui image: cancelling the first question does nothing" {
    command -v convert &> /dev/null || skip "imagemagick not installed"
    load_gui
    set_answers  # empty queue -> ui_choose returns empty -> treated as cancel
    ( do_image "${TEST_TMP}/test_image.png" )
    [ "$?" -eq 0 ]
    assert_file_not_exists "${TEST_TMP}/test_image_q85.jpg"
}

# =============================================================================
# pdf
# =============================================================================

@test "gui pdf: single file compresses" {
    command -v gs &> /dev/null || skip "ghostscript not installed"
    load_gui
    set_answers "Recommended"
    ( do_pdf "${TEST_TMP}/test.pdf" )
    [ "$?" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_compressed.pdf"
}

@test "gui pdf: two files can be merged" {
    command -v gs &> /dev/null || skip "ghostscript not installed"
    load_gui
    set_answers "Merge into one PDF" "combined"
    ( do_pdf "${TEST_TMP}/test.pdf" "${TEST_TMP}/test2.pdf" )
    [ "$?" -eq 0 ]
    assert_file_exists "${TEST_TMP}/combined.pdf"
}

# =============================================================================
# video
# =============================================================================

@test "gui video: convert with mode + resolution" {
    command -v ffmpeg &> /dev/null || skip "ffmpeg not installed"
    load_gui
    set_answers "Smaller file" "Same as original"
    ( do_video "${TEST_TMP}/test_video.mp4" )
    [ "$?" -eq 0 ]
    assert_file_exists "${TEST_TMP}/test_video_h265.mp4"
}
