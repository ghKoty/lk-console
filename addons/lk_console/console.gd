# Copyright (c) 2025 ghKoty(https://github.com/ghKoty)
# Distributed under the MIT License. See LICENSE file for full license information.

class_name Console
extends OversamplingInheritance

const CONSOLE_VERSION: String = "2.2"
const INFO_COLOR: Color = Color.GRAY
const WARNING_COLOR: Color = Color("ffff70")
const ERROR_COLOR: Color = Color("ff7070")
## Contains [Console] instance(self).
static var instance: Console

## Strings from this [Dictionary] will be replaced with corresponding floats after calling [method float_from_string].
static var float_aliases: Dictionary[String, float] = {
    "true": 1.0,
    "false": 0.0,
    "on": 1.0,
    "off": 0.0
}

## Strings from this [Dictionary] will be replaced with corresponding ints after calling [method int_from_string].
static var int_aliases: Dictionary[String, int] = {
    "true": 1,
    "false": 0,
    "on": 1,
    "off": 0
}

## If set true, this [Console] will be hidden when it gets [code]ui_cancel[/code] input(by default when [kbd]Escape[/kbd] pressed).
@export var hide_on_cancel: bool = true
## If set true, duplicates native engine errors and warnings to this [Console] using custom [Logger].
@export var add_engine_logger: bool = true

var commands: Dictionary[String, Dictionary] = {}

var logger_instance: Logger

var CustomLogger = preload("res://addons/lk_console/lk_console_engine_logger.gd")

#region Static methods
## Tries to convert string to float using [member float_aliases], if it fails tries to use engine function, if it also fails, returns [code]null[/code].
static func float_from_string(string: String):
    string = string.to_lower()
    if string in float_aliases.keys():
        return float_aliases[string]
    
    if string.is_valid_float():
        return string.to_float()
    
    return null


## Tries to convert string to int using [member int_aliases], if it fails tries to use engine function, if it also fails, returns [code]null[/code].
static func int_from_string(string: String):
    if string in int_aliases.keys():
        return int_aliases[string]
    
    if string.is_valid_int():
        return string.to_int()
    
    return null
#endregion


#region Engine methods
func _ready() -> void:
    Console.instance = self
    
    if add_engine_logger:
        logger_instance = CustomLogger.new()
        OS.add_logger(logger_instance)
    
    bind_command("help", cmd_print_help, "Prints list of available commands.")
    bind_command("?", cmd_print_help, "Prints list of available commands.")
    bind_command("echo", cmd_echo, "Echo text back to console.")
    bind_command("clear", cmd_clear, "Clears console.")
    bind_command("cls", cmd_clear, "Clears console.")
    bind_command("openconsole", cmd_openconsole, "Opens console.")
    print_to_console("Welcome to LK Console %s, type \"help\" for commands list." % CONSOLE_VERSION)


func _unhandled_key_input(event: InputEvent) -> void:
    if hide_on_cancel and event.is_action_pressed("ui_cancel"):
        visible = false


func _exit_tree() -> void:
    OS.remove_logger(logger_instance)


func _on_command_input_text_submitted(new_text: String) -> void:
    if new_text.is_empty():
        return
    
    print_to_console("] %s" % new_text, Color.WHITE)
    %CommandInput.text = ""
    
    var errors = execute_command(new_text)
    for error in errors:
        print_to_console(error, ERROR_COLOR)


func _on_submit_button_down() -> void:
    _on_command_input_text_submitted(%CommandInput.text)


func _on_visibility_changed() -> void:
    if visible:
        MouseManager.use_mouse(self)
    else:
        MouseManager.free_mouse(self)
#endregion


#region Public methods
func parse_args(args_string: String) -> Array:
    var args: Array = []
    var current_arg: String = ""
    var in_quotes: bool = false
    var escape: bool = false

    for i in args_string.length():
        var character: String = args_string[i]
        
        if escape:
            current_arg += character
            escape = false
        elif character == "\\":
            escape = true
        elif character in ["\"", "'"]:
            in_quotes = not in_quotes
        elif character == " " and not in_quotes:
            if current_arg != "":
                args.append(current_arg)
                current_arg = ""
        else:
            current_arg += character

    if current_arg != "":
        args.append(current_arg)

    return args


## Opens console.
func open_console() -> void:
    if not visible:
        visible = true
        %CommandInput.grab_focus()


## Creates command with [param command_name], that will run [param callable].
func bind_command(command_name: String, callable: Callable, command_description: String = "", help_text: String = "") -> int:
    
    if command_name in commands.keys():
        return ERR_ALREADY_EXISTS
    
    if not is_instance_valid(instance):
        return ERR_LINK_FAILED
    
    if not callable.is_valid():
        return ERR_INVALID_PARAMETER
    
    commands[command_name] = {
        "callable": callable,
        "description": command_description,
        "help_text": help_text
    }
    return OK


## Deletes command by its [param command_name].
func unbind_command(command_name: String) -> int:
    if not command_name in commands.keys():
        return ERR_DOES_NOT_EXIST
    
    commands.erase(command_name)
    return OK


## Prints [param text] to console and engine output with [param color].
func print_to_console(text, color: Color = INFO_COLOR) -> void:
    text = str(text)
    color = Color(color, 1.0)
    
    print_rich("[color=%s]%s[/color]" % [color.to_html(false), text])
    
    if not %Messages.text.is_empty():
        %Messages.text += "\n"
    %Messages.text += "[color=%s]%s[/color]" % [color.to_html(false), text]
    
    for i in range(2):
        var tree = get_tree()
        if tree:
            await tree.process_frame
    %ScrollContainer.scroll_vertical = %MessagesContainer.size.y


## Executes command(s) from [param command_line] the same way as it is executed by user.
func execute_command(command_line: String) -> Array:
    var commands_split: Array = []
    var i: int = 0
    var current_string: String = ""
    var previous_symbol: String = ""
    var in_quotes: bool = false
    while i < command_line.length():
        if not in_quotes:
            if (i + 1) < command_line.length():
                var two = command_line.substr(i, 2)
                if two in ["&&", "||"]:
                    if not current_string.strip_edges().is_empty():
                        commands_split.append(current_string.strip_edges())
                    commands_split.append(two)
                    current_string = ""
                    i += 2
                    continue
            if command_line[i] == ";":
                if not current_string.strip_edges().is_empty():
                    commands_split.append(current_string.strip_edges())
                commands_split.append(command_line[i])
                current_string = ""
                i += 1
                continue
        if command_line[i] in ["\"", "'"] and previous_symbol != "\\":
            in_quotes = not in_quotes
        previous_symbol = command_line[i]
        current_string += command_line[i]
        i += 1
    
    if not current_string.strip_edges().is_empty():
        commands_split.append(current_string.strip_edges())
    
    var previous_command_result_code: int = 0
    var errors = []
    for command in commands_split:
        if command == ";":
            continue
        if command == "&&":
            if previous_command_result_code == OK:
                continue
            else:
                break
        if command == "||":
            if previous_command_result_code == OK:
                break
            else:
                continue
        
        var command_args: Array = parse_args(command)
        
        if command_args.size() == 0:
            previous_command_result_code = ERR_INVALID_DATA
        
        var command_name = command_args.pop_front()
        
        if not command_name in commands.keys():
            previous_command_result_code = ERR_DOES_NOT_EXIST
            errors.append("%s: Command not found. Type \"help\" for list of available commands" % command_name)
            continue
        
        if not commands[command_name]["callable"].is_valid():
            previous_command_result_code = ERR_LINK_FAILED
            errors.append("%s: Cannot execute the command due an internal error(invalid callable)!" % command_name)
            continue
        
        var result = commands[command_name]["callable"].call(command_name, command_args)
        if result is int:
            previous_command_result_code = result
        else:
            previous_command_result_code = OK
    
    previous_command_result_code = OK
    return errors
#endregion


#region Console commands
func cmd_print_help(_command_name: String, command_args: Array) -> void:
    if command_args.size() > 0:
        if command_args[0] in commands:
            if commands[command_args[0]]["description"].is_empty():
                print_to_console("Command has no description.")
            elif commands[command_args[0]]["help_text"].is_empty():
                print_to_console(commands[command_args[0]]["description"])
            else:
                print_to_console(commands[command_args[0]]["help_text"])
            return
    
    print_to_console("List of available commands:", Color.LIGHT_GRAY)
    
    for command_name in commands.keys():
        if commands[command_name]["description"].is_empty():
            print_to_console(command_name)
        else:
            print_to_console("%s - %s" % [command_name, commands[command_name]["description"]])
    
    print_to_console("Tip: you can typically write \"help <command_name>\" to get more detailed help.\nTip2: You can use next BASH-like command separators: \";\", \"&&\", \"||\"", Color.LIGHT_GRAY)


func cmd_echo(_command_name: String, command_args: Array) -> void:
    if command_args.size() > 0:
        print_to_console(command_args[0])


func cmd_clear(_command_name: String, _command_args: Array) -> void:
    %Messages.text = ""


func cmd_openconsole(_command_name: String, _command_args: Array) -> void:
    open_console()
#endregion
