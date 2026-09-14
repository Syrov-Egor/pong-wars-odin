package pong

import rl "vendor:raylib"

W_HEIGHT :: 600
W_WIDTH :: 600
SQUARE_SIZE :: 30
NUM_SQUARES_X :: W_WIDTH / SQUARE_SIZE
NUM_SQUARES_Y :: W_HEIGHT / SQUARE_SIZE

Colors :: enum {
	NightColor,
	DayColor,
}

Color_Palette: [Colors]rl.Color = {
	.NightColor = rl.GetColor(0x114C5AFF),
	.DayColor   = rl.GetColor(0xD9E8E3FF),
}

Ball :: struct {
	pos:           rl.Vector2,
	vel:           rl.Vector2,
	reverse_color: rl.Color,
	ball_color:    rl.Color,
}

Game_State :: struct {
	squares: [NUM_SQUARES_X][NUM_SQUARES_Y]rl.Color,
	balls:   [2]Ball,
}

main :: proc() {
	rl.SetConfigFlags({.MSAA_4X_HINT})
	rl.InitWindow(W_HEIGHT, W_WIDTH, "Pong wars")

	gs := init_game()

	for !rl.WindowShouldClose() {
		update(&gs)
		draw(&gs)
	}

	rl.CloseWindow()
}

init_game :: proc() -> Game_State {

	squares: [NUM_SQUARES_X][NUM_SQUARES_Y]rl.Color
	for i in 0 ..< NUM_SQUARES_X {
		for j in 0 ..< NUM_SQUARES_Y {
			squares[i][j] =
				i < NUM_SQUARES_X / 2 ? Color_Palette[.DayColor] : Color_Palette[.NightColor]
		}
	}

	balls := [2]Ball {
		{
			pos = {W_WIDTH / 4, W_HEIGHT / 2},
			vel = {8, -8},
			reverse_color = Color_Palette[.DayColor],
			ball_color = Color_Palette[.NightColor],
		},
		{
			pos = {(W_WIDTH / 4) * 3, W_HEIGHT / 2},
			vel = {-8, 8},
			reverse_color = Color_Palette[.NightColor],
			ball_color = Color_Palette[.DayColor],
		},
	}

	return Game_State{squares, balls}
}

update :: proc(gs: ^Game_State) {

}

draw :: proc(gs: ^Game_State) {
	rl.BeginDrawing()

	rl.ClearBackground(Color_Palette[.NightColor])
	draw_squares(gs)
	draw_balls(gs)

	rl.EndDrawing()
}

draw_squares :: proc(gs: ^Game_State) {
	for i in 0 ..< NUM_SQUARES_X {
		for j in 0 ..< NUM_SQUARES_Y {
			color := gs.squares[i][j]
			rl.DrawRectangle(
				i32(i * SQUARE_SIZE),
				i32(j * SQUARE_SIZE),
				SQUARE_SIZE,
				SQUARE_SIZE,
				color,
			)
		}
	}
}

draw_balls :: proc(gs: ^Game_State) {
	for ball in gs.balls {
		rl.DrawCircleV(ball.pos, f32(SQUARE_SIZE) / 2.0, ball.ball_color)
	}
}
