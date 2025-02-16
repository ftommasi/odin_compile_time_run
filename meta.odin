package meta

//We did a shameless lift of odin's core libs just to add a little bit of custom AST building and parsing
import "./ast"
import "./parser"
import "./tokenizer"

import "core:fmt"
import "core:os"
import "core:strings"

main :: proc() {
	file_path := "src/main.odin"
    // Read the File:
	data, ok := os.read_entire_file(file_path);assert(ok)
    file_string := string(data)
	// Parse Into the AST:
	p := parser.Parser{}
	file_ast := ast.File {
		src      = file_string,
		fullpath = file_path,
	}
	ok = parser.parse_file(&p, &file_ast); assert(ok)

	for line in strings.split(file_string, "\n") {
		fmt.println(line)
	}
	ctx := CTE{}

	ctx.pkg = file_ast.pkg_name

    cur_imports := ""
    for import_tag in file_ast.imports{
        cur_imports = strings.concatenate({cur_imports, "import " , import_tag.fullpath,"\n"})
    }
    fmt.println("FINAL Importing: \n", cur_imports) 


	compile_time_execution(ctx)
}

CTE :: struct {
	pkg:     string,
	imports: string,
	deps:    string,
	body:    string,
}

compile_time_execution :: proc(ctx: CTE) {
	template := `
    {pkg}
    
    import "core:fmt" //hack to capture return
    {imports}

    {deps}

    main :: proc() {
    {body}
    }
    `
}
