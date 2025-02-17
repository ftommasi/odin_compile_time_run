package src

import "core:fmt"
import rl "vendor:raylib"

copmile_time_raylib :: proc() {
    rl.InitWindow(800,400,"CTE demo")
    for !rl.WindowShouldClose(){
    rl.BeginDrawing()
        rl.ClearBackground({63,72,86,1})
    rl.EndDrawing()
    }
    rl.CloseWindow()
}
at_compile_time :: proc() {
    fmt.println("At compile time")
}

at_run_time :: proc() {
    fmt.println("At run time")
}

main :: proc() {
    at_run_time()
}

#run at_compile_time()

#run copmile_time_raylib()
