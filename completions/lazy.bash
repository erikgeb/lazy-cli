# Bash completion for lazy CLI
# Install: copy to /etc/bash_completion.d/ or source from .bashrc

_lazy_completions() {
    local cur prev words cword
    _init_completion || return

    local commands="pdf image video backup doctor version help"
    local pdf_commands="compress merge"
    local image_commands="convert"
    local video_commands="convert"
    local backup_commands="home"

    case "${cword}" in
        1)
            COMPREPLY=($(compgen -W "${commands}" -- "${cur}"))
            ;;
        2)
            case "${prev}" in
                pdf)
                    COMPREPLY=($(compgen -W "${pdf_commands}" -- "${cur}"))
                    ;;
                image)
                    COMPREPLY=($(compgen -W "${image_commands}" -- "${cur}"))
                    ;;
                video)
                    COMPREPLY=($(compgen -W "${video_commands}" -- "${cur}"))
                    ;;
                backup)
                    COMPREPLY=($(compgen -W "${backup_commands}" -- "${cur}"))
                    ;;
            esac
            ;;
        *)
            local cmd="${words[1]}"
            local subcmd="${words[2]}"

            case "${cmd}" in
                pdf)
                    case "${subcmd}" in
                        compress)
                            case "${prev}" in
                                -q|--quality)
                                    COMPREPLY=($(compgen -W "screen ebook printer prepress" -- "${cur}"))
                                    ;;
                                -o|--output)
                                    COMPREPLY=($(compgen -f -- "${cur}"))
                                    ;;
                                *)
                                    if [[ "${cur}" == -* ]]; then
                                        COMPREPLY=($(compgen -W "-q --quality -o --output" -- "${cur}"))
                                    else
                                        COMPREPLY=($(compgen -f -X '!*.pdf' -- "${cur}"))
                                    fi
                                    ;;
                            esac
                            ;;
                        merge)
                            case "${prev}" in
                                -o|--output)
                                    COMPREPLY=($(compgen -f -- "${cur}"))
                                    ;;
                                *)
                                    if [[ "${cur}" == -* ]]; then
                                        COMPREPLY=($(compgen -W "-o --output" -- "${cur}"))
                                    else
                                        COMPREPLY=($(compgen -f -X '!*.pdf' -- "${cur}"))
                                    fi
                                    ;;
                            esac
                            ;;
                    esac
                    ;;
                image)
                    case "${subcmd}" in
                        convert)
                            case "${prev}" in
                                -f|--format)
                                    COMPREPLY=($(compgen -W "jpg jpeg png webp gif bmp tiff" -- "${cur}"))
                                    ;;
                                -o|--output)
                                    COMPREPLY=($(compgen -f -- "${cur}"))
                                    ;;
                                -q|--quality|-r|--resize|-s|--size|-w|--width|-h|--height)
                                    COMPREPLY=()
                                    ;;
                                *)
                                    if [[ "${cur}" == -* ]]; then
                                        COMPREPLY=($(compgen -W "-f --format -q --quality -r --resize -s --size -w --width -h --height -g --gray -o --output" -- "${cur}"))
                                    else
                                        COMPREPLY=($(compgen -f -- "${cur}"))
                                    fi
                                    ;;
                            esac
                            ;;
                    esac
                    ;;
                video)
                    case "${subcmd}" in
                        convert)
                            case "${prev}" in
                                -m|--mode)
                                    COMPREPLY=($(compgen -W "balanced small quality" -- "${cur}"))
                                    ;;
                                -c|--codec)
                                    COMPREPLY=($(compgen -W "h265 h264" -- "${cur}"))
                                    ;;
                                -r|--resolution)
                                    COMPREPLY=($(compgen -W "input 4k 1080p 720p" -- "${cur}"))
                                    ;;
                                *)
                                    if [[ "${cur}" == -* ]]; then
                                        COMPREPLY=($(compgen -W "-m --mode -c --codec -r --resolution" -- "${cur}"))
                                    else
                                        COMPREPLY=($(compgen -f -- "${cur}"))
                                    fi
                                    ;;
                            esac
                            ;;
                    esac
                    ;;
                backup)
                    case "${subcmd}" in
                        home)
                            if [[ "${cur}" == -* ]]; then
                                COMPREPLY=($(compgen -W "-n --dry-run" -- "${cur}"))
                            else
                                COMPREPLY=($(compgen -d -- "${cur}"))
                            fi
                            ;;
                    esac
                    ;;
            esac
            ;;
    esac
}

complete -F _lazy_completions lazy
