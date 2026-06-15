package main

import "core:fmt"
import "core:os"

DEBUG :: false


// --------------------------- CLI COMMANDS
add :: proc(file_name: string, title: string, desc: string) {
	t := init(file_name)
	defer t.save_and_cleanup(t) // save and cleanup

	___ := t.load_tasks(t, true) // ignore error: just create a newy file

	if DEBUG do fmt.println("DEBUG:", t.tasks) // show current tasks

	t.new_task(t, title, desc)
}
// ---------------------------
list :: proc(file_name: string) {
	t := init(file_name)
	defer t.cleanup(&t.tasks) // cleanup

	err := t.load_tasks(t, false)
	if err != nil {
		fmt.println(err)
	}

	for item, index in t.tasks {
		fmt.printf("%d) [%s] - %s \t%s\n", index, item.id, item.title, item.desc)
	}
}
// ---------------------------

/*
  ["path", "cmd" ,"--file", "/data.txt", "--title", "some new title", "--desc", "some new desc"] 
*/

main :: proc() {
	args := os.args
	if DEBUG do fmt.println("DEBUG: ", args)


	if len(args) < 2 {
		fmt.println("usage:\n\ttasks <command>\ncommands:\n\tadd\n\tls")
		return
	}

	cmd := args[1]

	switch cmd {
	case "add":
		if len(args) != 8 {
			fmt.println(
				"usage:\n\ttasks add --file \"file_path\" --title \"some title\" --desc \"some description\"",
			)
			return
		}

		file, title, desc := "", "", ""
		if args[2] == "--file" || args[2] == "-f" do file = args[3]
		else {
			fmt.println("expected --file or -f")
			return
		}
		if args[4] == "--title" || args[4] == "-t" do title = args[5]
		else {
			fmt.println("expected --title or -t")
			return
		}
		if args[6] == "--desc" || args[6] == "-d" do desc = args[7]
		else {
			fmt.println("expected --desc or -d")
			return
		}

		add(file, title, desc) // add
	case "ls":
		fallthrough
	case "list":
		if len(args) != 4 {
			fmt.println("usage:\n\ttasks list --file \"file_path\"")
			return
		}

		file := ""
		if args[2] == "--file" || args[2] == "-f" do file = args[3]
		else {
			fmt.println("expected --file or -f")
			return
		}

		list(file)
	}

}
