package main

import "core:fmt"
import "core:os"
import "core:strings"

DEBUG :: false


// --------------------------- CLI COMMANDS
add :: proc(file_name: string, title: string, desc: string) {
	t := init(file_name)
	defer t.save_and_cleanup(t) // save and cleanup

	err := t.load_tasks(t, true)
	if err != nil {
		fmt.println(err)
		return
	}

	if DEBUG do fmt.println("DEBUG:", t.tasks) // show current tasks

	if err := t.new_task(t, title, desc); err != nil {
		fmt.println(err)
	}
}
// ---------------------------
list :: proc(file_name: string) {
	t := init(file_name)
	defer t.cleanup(&t.tasks) // cleanup

	err := t.load_tasks(t, false)
	if err != nil {
		return
	}

	for item, index in t.tasks {
		fmt.printf(
			"%d) [%s] - Title: %s \n\tDescription: %s\n\tCreated: %s\n",
			index,
			item.id,
			item.title,
			item.desc,
			item.date,
		)
	}
}
// ---------------------------
delete_task_file :: proc(file_name: string) {
	t := init(file_name)
	defer t.cleanup(&t.tasks)

	{ 	// {} so i can isolate the err variable
		// check if the file can be loaded to TaskCore
		err := t.load_tasks(t, false)
		if err != nil {
			fmt.println("deleting does not work")
			return
		}
	}

	{
		// delete file
		err := os.remove(file_name)
		if err != nil {
			fmt.println("ER: ", err)
		}
	}
}
// ---------------------------

remove_task :: proc(file_name, id: string) {
	t := init(file_name)
	defer t.save_and_cleanup(t) // cleanup

	err := t.load_tasks(t, false)
	if err != nil {
		fmt.println(err)
		return
	}

	for task, i in t.tasks {
		if strings.contains(task.id, id) {
			unordered_remove(&t.tasks, i)
			fmt.printf("deleted: \n\t%s\t%s \n\t %s", task.id, task.title, task.date)
			return
		}
	}

	fmt.println("couldn't find a task to delete")
}

// ---------------------------

/*
  ["path", "cmd" ,"--file", "/data.txt", "--title", "some new title", "--desc", "some new desc"] 
*/

main :: proc() {
	args := os.args
	if DEBUG do fmt.println("DEBUG: ", args)


	if len(args) < 2 {
		fmt.println("usage:\n\ttasks <command>\ncommands:\n\tadd\n\tls\n\tdeletefile")
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

		file: string
		if args[2] == "--file" || args[2] == "-f" do file = args[3]
		else {
			fmt.println("expected --file or -f")
			return
		}

		list(file)
	case "deletefile":
		fallthrough
	case "df":
		if len(args) != 3 {
			fmt.println("usage:\n\ttasks deletefile file_path")
			return
		}
		delete_task_file(args[2])
	case "rm":
		id: string
		file: string
		if len(args) != 6 {
			fmt.println("usage:\n\ttasks rm --file \"file_path\" --id \"task_id\"")
			return
		}
		if args[2] == "--file" || args[2] == "-f" do file = args[3]
		else {
			fmt.println("expected --file or -f")
			return
		}
		if args[4] == "--id" || args[4] == "-i" do id = args[5]
		else {
			fmt.println("expected --id or -i")
			return
		}

		remove_task(file, id)
	}

}
