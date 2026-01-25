# Test helper for lazy CLI tests
# Provides common setup, teardown, and utility functions

# Path to the lazy script
LAZY_CMD="${BATS_TEST_DIRNAME}/../lazy"

# Temporary directory for test files
TEST_TMP=""

# Setup function - called before each test
setup() {
    # Create a unique temp directory for each test
    TEST_TMP="$(mktemp -d)"
    export TEST_TMP

    # Create test fixtures
    create_test_fixtures
}

# Teardown function - called after each test
teardown() {
    # Clean up temp directory
    if [[ -n "$TEST_TMP" && -d "$TEST_TMP" ]]; then
        rm -rf "$TEST_TMP"
    fi
}

# Create test fixtures (images, PDFs, etc.)
create_test_fixtures() {
    # Create a simple test image (red 100x100 PNG)
    if command -v convert &> /dev/null; then
        convert -size 100x100 xc:red "${TEST_TMP}/test_image.png"
        convert -size 100x100 xc:blue "${TEST_TMP}/test_image2.png"
        convert -size 200x100 xc:green "${TEST_TMP}/test_landscape.png"
        convert -size 100x200 xc:yellow "${TEST_TMP}/test_portrait.png"
    fi

    # Create a simple test PDF
    if command -v gs &> /dev/null; then
        # Create a minimal PDF using echo and gs
        cat > "${TEST_TMP}/test.pdf" << 'EOFPDF'
%PDF-1.4
1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj
2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj
3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] >> endobj
xref
0 4
0000000000 65535 f
0000000009 00000 n
0000000058 00000 n
0000000115 00000 n
trailer << /Size 4 /Root 1 0 R >>
startxref
196
%%EOF
EOFPDF
        # Create a second PDF for merge tests
        cp "${TEST_TMP}/test.pdf" "${TEST_TMP}/test2.pdf"
    fi

    # Create a simple test video
    if command -v ffmpeg &> /dev/null; then
        ffmpeg -f lavfi -i testsrc=duration=1:size=320x240:rate=10 \
            -c:v libx264 -pix_fmt yuv420p \
            "${TEST_TMP}/test_video.mp4" -y 2>/dev/null
    fi
}

# Helper: Run lazy command and capture output
run_lazy() {
    run "$LAZY_CMD" "$@"
}

# Helper: Assert file exists
assert_file_exists() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "Expected file to exist: $file" >&2
        return 1
    fi
}

# Helper: Assert file does not exist
assert_file_not_exists() {
    local file="$1"
    if [[ -f "$file" ]]; then
        echo "Expected file to not exist: $file" >&2
        return 1
    fi
}

# Helper: Assert output contains string
assert_output_contains() {
    local expected="$1"
    if [[ "$output" != *"$expected"* ]]; then
        echo "Expected output to contain: $expected" >&2
        echo "Actual output: $output" >&2
        return 1
    fi
}

# Helper: Get image dimensions
get_image_dimensions() {
    local file="$1"
    identify -format "%wx%h" "$file" 2>/dev/null
}

# Helper: Get video dimensions
get_video_dimensions() {
    local file="$1"
    ffprobe -v error -select_streams v:0 -show_entries stream=width,height \
        -of csv=s=x:p=0 "$file" 2>/dev/null
}

# Helper: Check if file is grayscale
is_grayscale() {
    local file="$1"
    local colorspace
    colorspace=$(identify -format "%[colorspace]" "$file" 2>/dev/null)
    [[ "$colorspace" == "Gray" ]]
}
