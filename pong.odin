package pong

import "core:fmt"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

W_HEIGHT :: 800
W_WIDTH :: 800
PANEL_HEIGHT :: 100
SLIDER_WIDTH :: 300
SLIDER_HEIGHT :: 20
WINDOW_WIDTH :: W_WIDTH
WINDOW_HEIGHT :: W_HEIGHT + PANEL_HEIGHT
TARGET_FPS :: 144

SQUARE_SIZE :: 40
NUM_SQUARES_X :: W_WIDTH / SQUARE_SIZE
NUM_SQUARES_Y :: W_HEIGHT / SQUARE_SIZE

MIN_SPEED :: 600
MAX_SPEED :: 1200
INITIAL_SPEED :: 900
JITTER_RANGE :: 700
SLIDER_MIN :: 0.0
SLIDER_MAX :: 5.0

mono_font: rl.Font

Colors :: enum {
	NightColor,
	DayColor,
	Background,
}

Color_Palette: [Colors]rl.Color = {
	.NightColor = rl.GetColor(0x114C5AFF),
	.DayColor   = rl.GetColor(0xD9E8E3FF),
	.Background = rl.GetColor(0x172B36FF),
}

Ball :: struct {
	pos:           rl.Vector2,
	vel:           rl.Vector2,
	reverse_color: rl.Color,
	ball_color:    rl.Color,
}

Game_State :: struct {
	squares:     [NUM_SQUARES_X][NUM_SQUARES_Y]rl.Color,
	balls:       [2]Ball,
	day_score:   int,
	night_score: int,
	speed:       f32,
}

main :: proc() {
	set_config()
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Pong wars")
	init_font()
	init_gui_style()

	gs := init_game()

	for !rl.WindowShouldClose() {
		update(&gs)
		draw(&gs)
	}

	rl.UnloadFont(mono_font)
	rl.CloseWindow()
}

set_config :: proc() {
	rl.SetConfigFlags({.MSAA_4X_HINT})
	rl.SetTargetFPS(TARGET_FPS)
}

init_game :: proc() -> Game_State {
	squares: [NUM_SQUARES_X][NUM_SQUARES_Y]rl.Color
	day_score, night_score: int
	for i in 0 ..< NUM_SQUARES_X {
		for j in 0 ..< NUM_SQUARES_Y {
			if i < NUM_SQUARES_X / 2 {
				squares[i][j] = Color_Palette[.DayColor]
				day_score += 1
			} else {
				squares[i][j] = Color_Palette[.NightColor]
				night_score += 1
			}
		}
	}

	balls := [2]Ball {
		{
			pos = {W_WIDTH / 4, W_HEIGHT / 2},
			vel = {INITIAL_SPEED, -INITIAL_SPEED},
			reverse_color = Color_Palette[.DayColor],
			ball_color = Color_Palette[.NightColor],
		},
		{
			pos = {(W_WIDTH / 4) * 3, W_HEIGHT / 2},
			vel = {-INITIAL_SPEED, INITIAL_SPEED},
			reverse_color = Color_Palette[.NightColor],
			ball_color = Color_Palette[.DayColor],
		},
	}

	return Game_State{squares, balls, day_score, night_score, 1.0}
}

update :: proc(gs: ^Game_State) {
	real_dt := rl.GetFrameTime()
	dt := real_dt * gs.speed

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
	rl.DrawRectangleGradientV(
		0,
		0,
		WINDOW_WIDTH,
		WINDOW_HEIGHT,
		Color_Palette[.Background],
		Color_Palette[.DayColor],
	)
	draw_squares(gs)
	draw_balls(gs)
	draw_panel(gs)

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

draw_panel :: proc(gs: ^Game_State) {
	text := fmt.ctprintf("day %3d | night %3d", gs.day_score, gs.night_score)
	font_size: f32 = 32.0
	text_width := rl.MeasureTextEx(mono_font, text, font_size, 0)

	text_x := (f32(W_WIDTH) - text_width.x) / 2
	text_y := f32(W_HEIGHT) + 15

	rl.DrawTextEx(mono_font, text, {text_x, text_y}, font_size, 0, Color_Palette[.NightColor])

	slider_x := f32(W_WIDTH - SLIDER_WIDTH) / 2
	slider_y := f32(W_HEIGHT + 60)

	rl.GuiSlider(
		{slider_x, slider_y, SLIDER_WIDTH, SLIDER_HEIGHT},
		"",
		"",
		&gs.speed,
		SLIDER_MIN,
		SLIDER_MAX,
	)

	label_font_size: f32 = 24
	rl.DrawTextEx(
		mono_font,
		"0x",
		{f32(slider_x) - 35.0, f32(slider_y) - 3},
		label_font_size,
		0,
		Color_Palette[.NightColor],
	)

	speed_label := fmt.ctprintf("%.1fx", gs.speed)
	rl.DrawTextEx(
		mono_font,
		speed_label,
		{f32(slider_x) + 315.0, f32(slider_y) - 3},
		label_font_size,
		0,
		Color_Palette[.NightColor],
	)
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
					if gs.squares[i][j] == Color_Palette[.DayColor] {
						gs.day_score -= 1
					} else {
						gs.night_score -= 1
					}
					if ball.reverse_color == Color_Palette[.DayColor] {
						gs.day_score += 1
					} else {
						gs.night_score += 1
					}

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

init_font :: proc() {
	mono_font = rl.LoadFontEx("assets/RobotoMono-Regular.ttf", 64, nil, 0)
	rl.SetTextureFilter(mono_font.texture, .BILINEAR)
}

init_gui_style :: proc() {
	night := i32(rl.ColorToInt(Color_Palette[.NightColor]))
	day := i32(rl.ColorToInt(Color_Palette[.DayColor]))

	rl.GuiSetStyle(.SLIDER, i32(rl.GuiControlProperty.BORDER_COLOR_NORMAL), night)
	rl.GuiSetStyle(.SLIDER, i32(rl.GuiControlProperty.BASE_COLOR_NORMAL), night)
	rl.GuiSetStyle(.SLIDER, i32(rl.GuiControlProperty.TEXT_COLOR_NORMAL), night)

	rl.GuiSetStyle(.SLIDER, i32(rl.GuiControlProperty.BORDER_COLOR_FOCUSED), night)
	rl.GuiSetStyle(.SLIDER, i32(rl.GuiControlProperty.BASE_COLOR_FOCUSED), day)
	rl.GuiSetStyle(.SLIDER, i32(rl.GuiControlProperty.TEXT_COLOR_FOCUSED), day)

	rl.GuiSetStyle(.SLIDER, i32(rl.GuiControlProperty.BORDER_COLOR_PRESSED), night)
	rl.GuiSetStyle(.SLIDER, i32(rl.GuiControlProperty.BASE_COLOR_PRESSED), day)
	rl.GuiSetStyle(.SLIDER, i32(rl.GuiControlProperty.TEXT_COLOR_PRESSED), day)
}
