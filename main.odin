package main

import "core:fmt"
import "core:math/rand"
import "core:os"
import "core:strings"

DEBUG :: true


Task :: struct {
	id:    string,
	title: string,
	desc:  string,
}

TaskCore :: struct {
	tasks:       [dynamic]Task,
	cleanup:     proc(tasks: ^[dynamic]Task),
	generate_id: proc() -> string,
	load_tasks:  proc(file_name: string) -> [dynamic]Task,
	save_tasks:  proc(tasks: [dynamic]Task, file_name: string),
	new_task:    proc(tasks: ^[dynamic]Task, title: string, desc: string),
}

new_task_core :: proc() -> ^TaskCore {
	core := new(TaskCore)
	core.cleanup = cleanup
	core.load_tasks = load_tasks
	core.save_tasks = save_tasks
	core.new_task = new_task
	return core
}

generate_id :: proc() -> string {
	bytes: [16]u8

	___ := rand.read(bytes[:])

	return fmt.aprintf(
		"%02x%02x%02x%02x-" + "%02x%02x-" + "%02x%02x-" + "%02x%02x-" + "%02x%02x%02x%02x%02x%02x",
		bytes[0],
		bytes[1],
		bytes[2],
		bytes[3],
		bytes[4],
		bytes[5],
		bytes[6],
		bytes[7],
		bytes[8],
		bytes[9],
		bytes[10],
		bytes[11],
		bytes[12],
		bytes[13],
		bytes[14],
		bytes[15],
	)
}

cleanup :: proc(tasks: ^[dynamic]Task) {
	for v in tasks^ {
		delete(v.id) // using aprint
		delete(v.title) // clone
		delete(v.desc) // clone
	}
	delete(tasks^)
}

new_file :: proc(file_name: string) -> []byte {
	file, err := os.create(file_name)
	if err != nil {
		panic(os.error_string(err))
	}
	defer os.close(file)

	data: []byte

	data, err = os.read_entire_file(file, context.allocator)
	return data
}

new_task :: proc(tasks: ^[dynamic]Task, title: string, desc: string) {
	id := generate_id()
	append(tasks, Task{strings.clone(id), strings.clone(title), strings.clone(desc)})
}

load_tasks :: proc(file_name: string) -> [dynamic]Task {
	tasks := make([dynamic]Task, context.allocator)

	err: os.Error
	file: []byte


	file, err = os.read_entire_file(file_name, context.allocator)
	if err != nil {
		file = new_file(file_name)
	}

	defer delete(file)

	lines := strings.split_lines(string(file), context.allocator)
	defer delete(lines)

	for line in lines {
		if len(strings.trim_space(line)) == 0 do continue // escape empty lines
		clean_line := strings.trim_space(line)
		parts := strings.split(clean_line, ",", context.allocator)

		defer delete(parts)

		if len(parts) < 3 do panic(line)

		id := generate_id()

		// need to clean up clones
		title := strings.clone(strings.trim_space(parts[1]))
		desc := strings.clone(strings.trim_space(parts[2]))

		append(&tasks, Task{id, title, desc})
	}
	return tasks
}

save_tasks :: proc(tasks: [dynamic]Task, file_name: string) {
	lines := make([]string, len(tasks))
	defer delete(lines) // clean lines

	for t, i in tasks {
		line := fmt.aprintf("%s, %s, %s", t.id, t.title, t.desc)
		lines[i] = line
	}
	defer for line in lines do delete(line) // clean aprint line

	file_content := strings.join(lines, "\n")
	defer delete(file_content, context.allocator)

	err := os.write_entire_file(file_name, string(file_content))
	if err != nil {
		fmt.println(err)
	}
}

// ---------------------------
// CLI
add :: proc(file_name: string, title: string, desc: string) {
	core := new_task_core()

	defer core.cleanup(&core.tasks) // second to cleanup
	defer core.save_tasks(core.tasks, file_name) // first save

	core.load_tasks(file_name)
	core.new_task(&core.tasks, title, desc)
}
// ---------------------------

/*
  ["path", "--file", "/data.txt", "--title", "some new title", "--desc", "some new desc"] 
*/
main :: proc() {
	args := os.args
	if DEBUG do fmt.println("DEBUG: ", args)
	if len(args) < 8 {
		fmt.println(
			"usage: \nadd --file \"file_path\" --title \"some title\" --desc \"some description\"",
			"\ndelete --file \"file_path\" --id \"some id\"",
		)
	}
}
