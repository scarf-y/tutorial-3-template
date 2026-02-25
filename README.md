# Latihan Mandiri: Eksplorasi Mekanika Pergerakan

README ini menjelaskan implementasi sistem movement karakter menggunakan `CharacterBody2D` dalam Godot.

Fitur yang diimplementasikan:

* Double Jump
* Crouching (dengan perubahan collider & kecepatan)
* Teleport (dengan animasi "clap" dan cooldown)

## 1. Double Jump

### Konsep

Karakter dapat melompat lebih dari satu kali sebelum menyentuh tanah.

Variabel yang digunakan:

```gdscript
@export var max_jumps := 2
var jump_count := 0
```

### Mekanisme

* Saat menyentuh tanah (`is_on_floor()`), `jump_count` direset ke 0.
* Ketika tombol lompat ditekan:

  * Jika `jump_count < max_jumps`
  * Maka karakter melompat dan `jump_count` bertambah 1.

```gdscript
if is_on_floor():
    jump_count = 0

if Input.is_action_just_pressed("ui_accept") and not is_crouching and jump_count < max_jumps:
    velocity.y = JUMP_VELOCITY
    jump_count += 1
```

## 2. Crouching System

### Konsep

Saat crouch:

* Sprite berubah ke animasi "crouch"
* Kecepatan gerak lebih lambat
* Collider berubah menjadi lebih kecil
* Tidak bisa berdiri jika ada langit-langit di atas

### Node yang Digunakan

* `CollisionStanding`
* `CollisionCrouching`
* `RayCast2D` (untuk cek langit-langit)

### Mekanisme

#### Aktivasi Crouch

```gdscript
var crouch_input = Input.is_action_pressed("crouch")

if crouch_input and is_on_floor():
    is_crouching = true
elif not crouch_input:
    if not ceiling_ray.is_colliding():
        is_crouching = false
```

Raycast digunakan untuk mencegah karakter berdiri jika ada obstacle di atasnya.

#### Perubahan Kecepatan

```gdscript
var current_speed = SPEED
if is_crouching:
    current_speed = CROUCH_SPEED
```

#### Update Collider

```gdscript
func update_collider():
    if is_crouching:
        stand_col.disabled = true
        crouch_col.disabled = false
    else:
        stand_col.disabled = false
        crouch_col.disabled = true
```

---

## 3. Teleport/Blink System (Clap Before Teleport)

Terinspirasi dari konsep teleportasi dengan gesture terlebih dahulu (specifically Todo Aoi dari Jujutsu Kaisen). 

### Fitur

* Karakter melakukan animasi "clap" sebelum teleport
* Teleport tidak bisa di-spam (menggunakan cooldown)
* Teleport dibatalkan jika ada obstacle di depan

### Variabel

```gdscript
@export var teleport_distance := 200.0
@export var teleport_cooldown := 1.5

var can_teleport := true
var is_teleporting := false
```

---

### Proses Teleport

#### 1. Input Check

```gdscript
if Input.is_action_just_pressed("teleport") and can_teleport and not is_teleporting:
    start_teleport()
```

#### 2. Main Teleport Function

```gdscript
func start_teleport():
    is_teleporting = true
    can_teleport = false
    
    velocity = Vector2.ZERO
    animated_sprite.play("clap")
    
    var anim_length = animated_sprite.sprite_frames.get_frame_count("clap") 
        / animated_sprite.sprite_frames.get_animation_speed("clap")
    
    await get_tree().create_timer(anim_length).timeout
    
    do_teleport()
```

Durasi animasi dihitung manual berdasarkan:

* Jumlah frame
* FPS animasi

#### 3. Cek Obstacle dengan Raycast

```gdscript
var query = PhysicsRayQueryParameters2D.create(
    global_position,
    target_position
)
query.exclude = [self]

var result = space_state.intersect_ray(query)
```

Jika tidak ada collision, posisi dipindahkan.

#### 4. Cooldown

```gdscript
func start_cooldown():
    await get_tree().create_timer(teleport_cooldown).timeout
    can_teleport = true
```

## 4. Animation State Logic

Prioritas animasi:

1. Crouch
2. Jump / Fall
3. Walk
4. Idle

```gdscript
if is_crouching:
    play_anim("crouch")
elif not is_on_floor():
    ...
```

Fungsi `play_anim()` mencegah animasi di-play ulang setiap frame:

```gdscript
func play_anim(animation_name):
    if animated_sprite.animation != animation_name:
        animated_sprite.play(animation_name)
```

## Referensi

* Godot 4 Documentation – CharacterBody2D
  [https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html](https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html)

* Godot 4 Documentation – RayCast2D
  [https://docs.godotengine.org/en/stable/classes/class_raycast2d.html](https://docs.godotengine.org/en/stable/classes/class_raycast2d.html)

* Godot 4 Documentation – AnimatedSprite2D
  [https://docs.godotengine.org/en/stable/classes/class_animatedsprite2d.html](https://docs.godotengine.org/en/stable/classes/class_animatedsprite2d.html)

* Godot 4 Documentation – Timers
  [https://docs.godotengine.org/en/stable/classes/class_timer.html](https://docs.godotengine.org/en/stable/classes/class_timer.html)

* Godot 2D Sprite Animation - IcyEngine [https://www.youtube.com/watch?v=-f1bHR0iiEY](https://www.youtube.com/watch?v=-f1bHR0iiEY)

* Aoi Todo Fully Explained [https://youtu.be/TXMVJHwUKxA?si=DlDHo7kJBu0darYN](https://youtu.be/TXMVJHwUKxA?si=DlDHo7kJBu0darYN)

