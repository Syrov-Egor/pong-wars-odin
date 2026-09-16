package pong

import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

W_HEIGHT :: 800
W_WIDTH :: 800
SQUARE_SIZE :: 40
TARGET_FPS :: 144
NUM_SQUARES_X :: W_WIDTH / SQUARE_SIZE
NUM_SQUARES_Y :: W_HEIGHT / SQUARE_SIZE
JITTER_RANGE :: 700
INITIAL_VELOCITY :: 900
MIN_SPEED :: 600
MAX_SPEED :: 1200

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
	set_config()
	rl.InitWindow(W_HEIGHT, W_WIDTH, "Pong wars")

	gs := init_game()

	for !rl.WindowShouldClose() {
		update(&gs)
		draw(&gs)
	}

	rl.CloseWindow()
}

set_config :: proc() {
	rl.SetConfigFlags({.MSAA_4X_HINT})
	rl.SetTargetFPS(TARGET_FPS)
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
			vel = {INITIAL_VELOCITY, -INITIAL_VELOCITY},
			reverse_color = Color_Palette[.DayColor],
			ball_color = Color_Palette[.NightColor],
		},
		{
			pos = {(W_WIDTH / 4) * 3, W_HEIGHT / 2},
			vel = {-INITIAL_VELOCITY, INITIAL_VELOCITY},
			reverse_color = Color_Palette[.NightColor],
			ball_color = Color_Palette[.DayColor],
		},
	}

	return Game_State{squares, balls}
}

update :: proc(gs: ^Game_State) {
	dt := rl.GetFrameTime()

	check_square_collision(gs)
	check_boundary_collision(gs, dt)
	for &ball in gs.balls {
		ball.pos.x += ball.vel.x * dt
		ball.pos.y += ball.vel.y * dt
	}
	add_randomness(gs, dt)
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

check_square_collision :: proc(gs: ^Game_State) {
	for &ball in gs.balls {
		for angle := f32(0); angle < math.PI * 2.0; angle += math.PI / 4.0 {
			check_x := ball.pos.x + math.cos(angle) * (f32(SQUARE_SIZE) / 2.0)
			check_y := ball.pos.y + math.sin(angle) * (f32(SQUARE_SIZE) / 2.0)
			i := int(math.floor(check_x / f32(SQUARE_SIZE)))
			j := int(math.floor(check_y / f32(SQUARE_SIZE)))

			if (i >= 0 && i < NUM_SQUARES_X && j >= 0 && j < NUM_SQUARES_Y) {
				if (gs.squares[i][j] != ball.reverse_color) {
					gs.squares[i][j] = ball.reverse_color

					if abs(math.cos(angle)) > abs(math.sin(angle)) {
						ball.vel.x = -ball.vel.x
					} else {
						ball.vel.y = -ball.vel.y
					}
				}
			}
		}
	}
}

check_boundary_collision :: proc(gs: ^Game_State, dt: f32) {
	for &ball in gs.balls {
		if ball.pos.x + ball.vel.x * dt > W_WIDTH - f32(SQUARE_SIZE) / 2.0 ||
		   ball.pos.x + ball.vel.x * dt < f32(SQUARE_SIZE) / 2.0 {
			ball.vel.x = -ball.vel.x
		}
		if ball.pos.y + ball.vel.y * dt > W_HEIGHT - f32(SQUARE_SIZE) / 2.0 ||
		   ball.pos.y + ball.vel.y * dt < f32(SQUARE_SIZE) / 2.0 {
			ball.vel.y = -ball.vel.y
		}
	}
}

add_randomness :: proc(gs: ^Game_State, dt: f32) {
	for &ball in gs.balls {
		ball.vel.x += (rand.float32() * JITTER_RANGE - JITTER_RANGE / 2) * dt
		ball.vel.y += (rand.float32() * JITTER_RANGE - JITTER_RANGE / 2) * dt

		ball.vel.x = min(max(ball.vel.x, -MAX_SPEED), MAX_SPEED)
		ball.vel.y = min(max(ball.vel.y, -MAX_SPEED), MAX_SPEED)

		if abs(ball.vel.x) < MIN_SPEED {
			ball.vel.x = MIN_SPEED if ball.vel.x > 0 else -MIN_SPEED
		}
		if abs(ball.vel.y) < MIN_SPEED {
			ball.vel.y = MIN_SPEED if ball.vel.y > 0 else -MIN_SPEED
		}
	}
}
