package game

import rl "vendor:raylib"
import "core:math"
import "core:fmt"

ASTEROID_POINTS := [?][]rl.Vector2 {
    []rl.Vector2 {{-10, -10}, {-10, 10}, {10, 10}, {10, -10}, {-10, -10}},
    []rl.Vector2 {{-10, -5}, {0, -10}, {5, -5}, {5, 10}, {-10, 10}, {-10, -5}}
}

asteroidData :: struct{
    using position : rl.Vector2,
    rotation : f32,
    velocity : rl.Vector2,
    angularVelocity : f32,
    type : int
}

UpdateAsteroids :: proc(asteroids : ^[dynamic]asteroidData){

    for &asteroid in asteroids {
        asteroid.position += asteroid.velocity * rl.GetFrameTime()
        asteroid.rotation += asteroid.angularVelocity * rl.GetFrameTime()
    }

}

CreateNewAsteroid :: proc(asteroids : ^[dynamic]asteroidData, position : rl.Vector2, rotation : f32, velocity : rl.Vector2, angularVelocity : f32){
    append(asteroids, asteroidData{position, rotation, velocity, angularVelocity, int(rl.GetRandomValue(0, len(ASTEROID_POINTS)-1))})
}

SpawnNewAsteroid :: proc(asteroids : ^[dynamic]asteroidData){
    is_horizontal : bool = rl.GetRandomValue(0, 1) == 0
    max_pos : i32 = GAME_WIDTH if is_horizontal else GAME_HEIGHT

    pos : i32 = rl.GetRandomValue(0, max_pos)

    is_max_perpendicular : bool = rl.GetRandomValue(0, 1) == 0
    perpendicular_pos : i32 = 0 if is_max_perpendicular else (GAME_HEIGHT if is_horizontal else GAME_WIDTH)

    spawned_pos : rl.Vector2 = {f32(pos), f32(perpendicular_pos)} if is_horizontal else {f32(perpendicular_pos), f32(pos)}
    
    ran_vel : i32 = rl.GetRandomValue(10, 100)
    ran_vel_perpendicular : i32 = rl.GetRandomValue(-100, 100)
    vel_dir := i32(math.sign(f32(GAME_WIDTH/2 - perpendicular_pos)))
    spawned_velocity : rl.Vector2 = {f32(ran_vel * vel_dir), f32(ran_vel_perpendicular)} if !is_horizontal else {f32(ran_vel_perpendicular), f32(ran_vel * vel_dir)}

    CreateNewAsteroid(asteroids, spawned_pos, f32(rl.GetRandomValue(0, 360)), spawned_velocity, 0)
}