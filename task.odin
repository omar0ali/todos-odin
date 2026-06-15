package main
import "core:fmt"
import "core:math/rand"
import "core:os"
import "core:strings"

Error :: enum {
	FileNotFound,
	InvalidInput,
}

@(private = "file")
Task :: struct {
	id:    string,
	title: string,
	desc:  string,
}

TaskCore :: struct {
	file_name:        string,
	tasks:            [dynamic]Task,
	generate_id:      proc() -> string,
	load_tasks:       proc(t_core: ^TaskCore, create_file: bool) -> Error,
	save_and_cleanup: proc(t_core: ^TaskCore),
	cleanup:          proc(tasks: ^[dynamic]Task),
	new_task:         proc(t_core: ^TaskCore, title: string, desc: string),
}

init :: proc(file_name: string) -> ^TaskCore {
	core := new(TaskCore)
	core.file_name = file_name
	core.load_tasks = load_tasks
	core.save_and_cleanup = save_tasks
	core.cleanup = cleanup
	core.new_task = new_task
	return core
}

@(private = "file")
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

@(private = "file")
cleanup :: proc(tasks: ^[dynamic]Task) {
	for v in tasks^ {
		delete(v.id) // using aprint
		delete(v.title) // clone
		delete(v.desc) // clone
	}
	delete(tasks^)
}

@(private = "file")
new_file :: proc(t_core: ^TaskCore) -> []byte {
	file, err := os.create(t_core.file_name)
	if err != nil {
		panic(os.error_string(err))
	}
	defer os.close(file)

	data: []byte

	data, err = os.read_entire_file(file, context.allocator)
	return data
}

@(private = "file")
new_task :: proc(t_core: ^TaskCore, title: string, desc: string) {
	id := generate_id()
	append(&t_core.tasks, Task{strings.clone(id), strings.clone(title), strings.clone(desc)})
}

@(private = "file")
load_tasks :: proc(t_core: ^TaskCore, create_file: bool) -> Error {
	tasks := make([dynamic]Task, context.allocator)

	err: os.Error
	file: []byte


	file, err = os.read_entire_file(t_core.file_name, context.allocator)
	if err != nil {
		if create_file do file = new_file(t_core)
		fmt.println(err, " file does not exist")
		return .FileNotFound
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
	t_core.tasks = tasks
	return nil
}

@(private = "file")
save_tasks :: proc(t_core: ^TaskCore) {
	lines := make([]string, len(t_core.tasks))
	defer cleanup(&t_core.tasks)
	defer delete(lines) // clean lines

	for t, i in t_core.tasks {
		line := fmt.aprintf("%s, %s, %s", t.id, t.title, t.desc)
		lines[i] = line
	}
	defer for line in lines do delete(line) // clean aprint line

	file_content := strings.join(lines, "\n")
	defer delete(file_content, context.allocator)

	err := os.write_entire_file(t_core.file_name, string(file_content))
	if err != nil {
		fmt.println(err)
	}
}
