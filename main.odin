package main

import "core:fmt"
import "core:os"
import "task"

DEBUG :: true


// --------------------------- CLI COMMANDS
add :: proc(file_name: string, title: string, desc: string) {
	t := task.init(file_name)
	defer t.save_and_cleanup(t) // save and cleanup

	t.load_tasks(t)

	if DEBUG do fmt.println("DEBUG:", t.tasks) // show current tasks

	t.new_task(t, title, desc)
}
// ---------------------------

/*
  ["path", "--file", "/data.txt", "--title", "some new title", "--desc", "some new desc"] 
*/

main :: proc() {
	args := os.args
	if DEBUG do fmt.println("DEBUG: ", args)
	add("data.txt", "title", "desc")
	// if len(args) < 8 {
	// 	fmt.println(
	// 		"usage: \nadd --file \"file_path\" --title \"some title\" --desc \"some description\"",
	// 		"\ndelete --file \"file_path\" --id \"some id\"",
	// 	)
	// }
}
