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

    //for each `#run` statement
    for cte_run in file_ast.cte_run_stmts{
        cur_imports := "" //TODO lets change this out for a string builder...
        for import_tag in file_ast.imports{

            //This is some nasty hack. Because we currently plan to capture the output via stdio
            // then we MUST always include core:fmt in the CTE program, so to avoid duplicate imports just ignore
            if !strings.contains(import_tag.fullpath, "core:fmt") {
                cur_imports = strings.concatenate({cur_imports, "import " , import_tag.fullpath,"\n"})//TODO lets change this out for a string builder...
            }
        }
        fmt.println("FINAL Importing: \n", cur_imports) 
         
        //HACK ALERT: Here comes another series of hacks: 
        // 1. To make sure we include all the dependencies for our CTE run function, we just include the file //TODO maybe include all the files in the package as well
        // 2. To avoid having to detect the main proc, we just do a simple string replace and treat it as a regular proc
        
        //TODO fix the source of the bug here
        without_main , _ := strings.replace_all(file_string,"main","_main") //this could mess up some strings so we need to be carefule
        cur_deps := without_main 
	    ctx := CTE{
	        pkg = file_ast.pkg_name,
            imports = cur_imports,
            deps = cur_deps,
            body = file_string[cte_run.node.pos.offset:cte_run.node.end.offset],
        }

	    compile_time_execution(ctx)
    }
}

CTE :: struct {
	pkg:     string,
	imports: string,
	deps:    string,
	body:    string,
}

compile_time_execution :: proc(ctx: CTE) {
	template := `
    package {pkg}
    
    import "core:fmt" //hack to capture return
    {imports}

    {deps}

    main :: proc() {
        {body}
    }
    `
    with_pkg , _ := strings.replace_all(template,"{pkg}",ctx.pkg)
    with_imports , _ := strings.replace_all(with_pkg,"{imports}",ctx.imports)
    with_deps , _ := strings.replace_all(with_imports,"{deps}",ctx.deps)
    final_cte_program , _ := strings.replace_all(with_deps,"{body}",ctx.body)

    fmt.println("CTE: ",final_cte_program )

    //now that we have our meta program ready, write it to disk and spawn an odin process and then capture output
}
