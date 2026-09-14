package pong

import rl "vendor:raylib"

WINDOW_SIZE :: 800

main :: proc() {
	rl.InitWindow(WINDOW_SIZE, WINDOW_SIZE, "Pong wars")

	init_game()

	for !rl.WindowShouldClose() {
		update()
		draw()
	}

	rl.CloseWindow()
}

init_game :: proc() {

}

update :: proc() {

}

draw :: proc() {
	rl.BeginDrawing()

	my_color := rl.GetColor(0xD9E8E3FF)
	rl.ClearBackground(my_color)

	rl.EndDrawing()
}
