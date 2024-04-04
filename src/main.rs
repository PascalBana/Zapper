use bevy::prelude::*;

fn main() {
    App::new()
        .add_plugins(DefaultPlugins)
        .add_systems(Startup, (hello_world, spawn_camera))
        .run();
}

fn hello_world() {
    println!("Hello, world!");
}

fn spawn_camera(mut commands: Commands) {
    commands.spawn(Camera2dBundle {
        camera: Camera {
            clear_color: ClearColorConfig::Custom(Color::rgb(0.8, 0.6, 0.7)),
            ..default()
        },
        ..default()
    });
}