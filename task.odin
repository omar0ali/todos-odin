package main
import "core:fmt"
import "core:math/rand"
import "core:os"
import "core:strings"
import "core:time"

Error :: enum {
	FileNotFound,
	InvalidInput,
	InvalidTime,
}

@(private = "file")
Task :: struct {
	id:    string,
	title: string,
	desc:  string,
	date:  string,
}

TaskCore :: struct {
	file_name:        string,
	tasks:            [dynamic]Task,
	load_tasks:       proc(t_core: ^TaskCore, create_file: bool) -> Error,
	save_and_cleanup: proc(t_core: ^TaskCore),
	cleanup:          proc(tasks: ^[dynamic]Task),
	new_task:         proc(t_core: ^TaskCore, title: string, desc: string) -> Error,
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
		delete(v.date)
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
new_task :: proc(t_core: ^TaskCore, title: string, desc: string) -> Error {
	id := generate_id() // creating a new id

	now, ok := time.time_to_datetime(time.now())
	if !ok {
		return .InvalidTime
	}

	hour_12 := now.hour % 12
	if hour_12 == 0 {
		hour_12 = 12
	}

	ampm := "AM"
	if now.hour >= 12 {
		ampm = "PM"
	}

	date := fmt.tprintf(
		"%02d/%02d/%04d %d:%02d %s",
		now.day,
		int(now.month),
		now.year,
		hour_12,
		now.minute,
		ampm,
	)

	new_task_created := Task {
		strings.clone(id),
		strings.clone(title),
		strings.clone(desc),
		strings.clone(date),
	}

	append(&t_core.tasks, new_task_created)
	return nil
}

@(private = "file")
load_tasks :: proc(t_core: ^TaskCore, create_file: bool) -> Error {
	tasks := make([dynamic]Task, context.allocator)

	err: os.Error
	file: []byte


	file, err = os.read_entire_file(t_core.file_name, context.allocator)
	if err != nil {
		if create_file {
			file = new_file(t_core)
			return nil
		}
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

		if len(parts) < 4 do panic(line)

		// need to clean up clones
		id := strings.clone(strings.trim_space(parts[0])) // saved id
		title := strings.clone(strings.trim_space(parts[1]))
		desc := strings.clone(strings.trim_space(parts[2]))
		date := strings.clone(strings.trim_space(parts[3]))

		append(&tasks, Task{id, title, desc, date})
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
		line := fmt.aprintf("%s, %s, %s, %s", t.id, t.title, t.desc, t.date)
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
