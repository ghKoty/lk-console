# Copyright (c) 2025 ghKoty(https://github.com/ghKoty)
# Distributed under the MIT License. See LICENSE file for full license information.

class_name OversamplingInheritance
extends Window

func _process(_delta: float) -> void:
    oversampling_override = get_tree().get_root().oversampling_override
