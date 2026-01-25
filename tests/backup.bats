#!/usr/bin/env bats
# Backup command tests

load 'test_helper'

# Skip all tests if rsync is not installed
setup() {
    if ! command -v rsync &> /dev/null; then
        skip "rsync not installed"
    fi
    TEST_TMP="$(mktemp -d)"
    export TEST_TMP

    # Create a mock home directory structure for testing
    mkdir -p "${TEST_TMP}/mock_home"
    mkdir -p "${TEST_TMP}/mock_home/Documents"
    mkdir -p "${TEST_TMP}/mock_home/.cache"
    mkdir -p "${TEST_TMP}/mock_home/node_modules"
    echo "test file" > "${TEST_TMP}/mock_home/test.txt"
    echo "document" > "${TEST_TMP}/mock_home/Documents/doc.txt"
    echo "cache data" > "${TEST_TMP}/mock_home/.cache/cache.dat"
    echo "node module" > "${TEST_TMP}/mock_home/node_modules/module.js"

    # Create backup destination
    mkdir -p "${TEST_TMP}/backup_dest"

    # Clear any saved config for testing
    rm -f "${HOME}/.config/lazy/config"
}

# =============================================================================
# backup home tests
# =============================================================================

@test "backup home shows help without arguments and no saved volume" {
    run_lazy backup home
    assert_output_contains "Usage: lazy backup home"
    [ "$status" -eq 1 ]
}

@test "backup home fails with nonexistent volume" {
    run_lazy backup home "${TEST_TMP}/nonexistent_volume"
    assert_output_contains "Volume not found"
    [ "$status" -eq 1 ]
}

@test "backup home dry-run shows what would be transferred" {
    run_lazy backup home "${TEST_TMP}/backup_dest" -n
    assert_output_contains "DRY RUN"
    [ "$status" -eq 0 ]
}

@test "backup home accepts --dry-run long option" {
    run_lazy backup home "${TEST_TMP}/backup_dest" --dry-run
    assert_output_contains "DRY RUN"
    [ "$status" -eq 0 ]
}

@test "backup home creates log file" {
    run_lazy backup home "${TEST_TMP}/backup_dest" -n
    [ "$status" -eq 0 ]
    # Log file should be created in home directory
    assert_output_contains "Log file:"
}

@test "backup home saves last used volume to config" {
    run_lazy backup home "${TEST_TMP}/backup_dest" -n
    [ "$status" -eq 0 ]

    # Check config file exists and contains the volume
    [ -f "${HOME}/.config/lazy/config" ]
    grep -q "backup_last_volume=${TEST_TMP}/backup_dest" "${HOME}/.config/lazy/config"
}

@test "backup home suggests last used volume" {
    # First run to save volume
    run_lazy backup home "${TEST_TMP}/backup_dest" -n

    # Second run without volume - should suggest the saved one
    run bash -c "echo 'n' | $LAZY_CMD backup home"
    assert_output_contains "Last used volume:"
    assert_output_contains "${TEST_TMP}/backup_dest"
}

@test "backup home uses last volume when user confirms" {
    # First run to save volume
    run_lazy backup home "${TEST_TMP}/backup_dest" -n

    # Second run - confirm using saved volume
    run bash -c "echo 'y' | $LAZY_CMD backup home -n"
    [ "$status" -eq 0 ]
    assert_output_contains "DRY RUN"
}

@test "backup home shows success message on completion" {
    run_lazy backup home "${TEST_TMP}/backup_dest" -n
    [ "$status" -eq 0 ]
    # Should show info about the backup
    assert_output_contains "Backing up"
}

# =============================================================================
# backup unknown subcommand
# =============================================================================

@test "backup unknown subcommand fails" {
    run_lazy backup unknownsub
    assert_output_contains "Unknown command: backup unknownsub"
    [ "$status" -eq 1 ]
}
