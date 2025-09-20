
# LK Console for Godot 4.5+

In-game developer console inspired by Source engine, made for Godot 4.
Allows you to register custom commands, print colored output, and interact with your project at runtime.

---

## ✨ Features
- Built-in commands (`help`, `echo`, `clear`, `openconsole`)
- BASH-like command separators (`;`, `&&`, `||`)
- Easy API to bind/unbind your own commands
- Colored console output
- Mouse handling (console switches mouse modes automatically)
- Supports native engine errors and warnings.

---

## 🚀 Installation
1. Copy the `addons` directory into your Godot project.
2. Add `console.tscn` to your main scene.

---

## 🔧 Quick usage example
```gdscript
extends Node

func _ready() -> void:
    Console.instance.bind_command("hello", cmd_print, "Outputs \"hello [name]!\" to console", "Outputs \"hello [name]!\" to console. Usage:\nhello [name]")
    Console.instance.bind_command("bye", cmd_print, "Outputs \"bye [name]!\" to console", "Outputs \"bye [name]!\" to console. Usage:\nbye [name]")


func _exit_tree() -> void:
    Console.instance.unbind_command("hello")
    Console.instance.unbind_command("bye")


func cmd_print(command_name: String, command_args: Array) -> void:
    if command_args.is_empty():
        Console.instance.print_to_console("Invalid arguments, type \"help %s\" for usage help!" % command_name, Console.ERROR_COLOR)
	    return
    Console.instance.print_to_console("%s %s!" % [command_name, command_args[0]])
```


## 📜 License & Code of Conduct
This project is licensed under the [MIT License](LICENSE).  
Please follow our [Code of Conduct](CODE_OF_CONDUCT.md) when contributing.
