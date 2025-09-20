# Copyright (c) 2025 ghKoty(https://github.com/ghKoty)
# Distributed under the MIT License. See LICENSE file for full license information.
extends Logger

## Custom logger, duplicates native engine errors and warnings to the [Console].

func _log_error(function: String, file: String, line: int, code: String, _rationale: String, _editor_notify: bool, error_type: int, script_backtraces: Array[ScriptBacktrace]) -> void:
        var message_color: Color
        match error_type:
            ERROR_TYPE_ERROR:
                message_color = Console.ERROR_COLOR
            ERROR_TYPE_SCRIPT:
                message_color = Console.ERROR_COLOR
            ERROR_TYPE_SHADER:
                message_color = Console.ERROR_COLOR
            ERROR_TYPE_WARNING:
                message_color = Console.WARNING_COLOR
            _:
                message_color = Console.INFO_COLOR
        
        print_script_error(message_color, function, file, line, code, script_backtraces)
        
        if OS.is_debug_build() or Engine.is_editor_hint():
            Console.instance.print_to_console("  <C++ Source>  %s:%d @ %s" % [file, line, function], message_color)
            for backtrace in script_backtraces:
                Console.instance.print_to_console(backtrace.format(2, 4), message_color)


func print_script_error(message_color: Color, function: String, file: String, line: int, code: String, script_backtraces: Array[ScriptBacktrace]) -> void:
    if not script_backtraces.is_empty():
        var last_backtrace: ScriptBacktrace = script_backtraces[0]
        if not last_backtrace.is_empty():
            file = last_backtrace.get_frame_file(0)
            line = last_backtrace.get_frame_line(0)
            function = last_backtrace.get_frame_function(0)
    
    Console.instance.print_to_console("Engine log: %s:%d @ %s: %s" % [file, line, function, code], message_color)
