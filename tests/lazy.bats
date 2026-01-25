#!/usr/bin/env bats
# Main lazy CLI tests - general commands and help

load 'test_helper'

@test "lazy --help shows usage" {
    run_lazy --help
    assert_output_contains "Usage: lazy <command>"
    assert_output_contains "pdf"
    assert_output_contains "image"
    assert_output_contains "video"
    assert_output_contains "backup"
    [ "$status" -eq 0 ]
}

@test "lazy help shows usage" {
    run_lazy help
    assert_output_contains "Usage: lazy <command>"
    [ "$status" -eq 0 ]
}

@test "lazy with no arguments shows help" {
    run_lazy
    assert_output_contains "Usage: lazy <command>"
    [ "$status" -eq 0 ]
}

@test "lazy version shows version number" {
    run_lazy version
    assert_output_contains "lazy v"
    [ "$status" -eq 0 ]
}

@test "lazy doctor checks dependencies" {
    run_lazy doctor
    assert_output_contains "System Check"
    assert_output_contains "Dependencies:"
    [ "$status" -eq 0 ]
}

@test "lazy unknown command fails with error" {
    run_lazy unknowncommand
    assert_output_contains "Unknown command"
    [ "$status" -eq 1 ]
}

@test "lazy pdf without subcommand shows help" {
    run_lazy pdf
    assert_output_contains "Usage: lazy pdf"
    assert_output_contains "compress"
    assert_output_contains "merge"
    [ "$status" -eq 0 ]
}

@test "lazy image without subcommand shows help" {
    run_lazy image
    assert_output_contains "Usage: lazy image"
    assert_output_contains "resize"
    assert_output_contains "convert"
    assert_output_contains "optimize"
    assert_output_contains "batch_convert"
    [ "$status" -eq 0 ]
}

@test "lazy video without subcommand shows help" {
    run_lazy video
    assert_output_contains "Usage: lazy video"
    assert_output_contains "convert"
    [ "$status" -eq 0 ]
}

@test "lazy backup without subcommand shows help" {
    run_lazy backup
    assert_output_contains "Usage: lazy backup"
    assert_output_contains "home"
    [ "$status" -eq 0 ]
}
