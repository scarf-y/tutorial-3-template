<details>
<summary> Tutorial 3 </summary>
    
## Latihan Mandiri: Eksplorasi Mekanika Pergerakan

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
---
</details>

<details>
<summary> Tutorial 5 </summary>
    
### **Implementasi Animasi, Audio, dan Variasi Aset**

#### **Proses Pengerjaan**

Pada tutorial ini, saya mempelajari cara mengintegrasikan aset visual (spritesheet) dan audio ke dalam mesin game Godot. Prosesnya dimulai dengan:

1. **Latihan Dasar**: Menggunakan `AnimatedSprite2D` untuk animasi karakter yang sudah ada, serta melakukan rekaman mandiri menggunakan *Audacity* untuk membuat SFX "Teleport/Blink" yang unik.
2. **Integrasi Audio**: Memasukkan audio ke dalam game menggunakan `AudioStreamPlayer` dan `AudioStreamPlayer2D` untuk memahami perbedaan antara suara global dan suara posisional.
3. **Latihan Mandiri (Radio System)**: Saya memutuskan untuk membuat sebuah objek interaktif berupa **Radio/Stereo**. Objek ini dirancang untuk menjadi pusat kendali musik di dalam level, yang menggabungkan logika interaksi pemain dengan sistem audio yang dinamis.

#### **Analisis Pemenuhan Tugas Mandiri**

Implementasi sistem Radio ini memenuhi poin-berpoin tugas mandiri sebagai berikut:

* **Objek Baru dengan Animasi Spritesheet**:
Saya menambahkan objek Radio yang memiliki spritesheet khusus. Objek ini memiliki tiga status animasi: `off` (mati), `on` (saat memutar musik), dan `change_visual` (transisi saat mengganti lagu). Ini memenuhi syarat pembuatan minimal satu objek baru di luar tutorial.
* **Minimal 1 Audio SFX**:
Syarat ini dipenuhi melalui **SFX Teleport/Blink** yang saya buat sendiri menggunakan Audacity. Suara ini dipicu setiap kali pemain melakukan aksi teleportasi di dalam game.
* **Minimal 1 Musik Latar (BGM)**:
Radio ini memuat sebuah `playlist` (Array dari `AudioStream`). Lagu-lagu seperti *Monkeys Spinning Monkeys* dan *Daisy* berfungsi sebagai BGM yang bisa dipilih oleh pemain.
* **Implementasi Interaksi**:
Pemain dapat berinteraksi dengan Radio menggunakan tombol `E` (untuk menyalakan/ganti lagu) dan `F` (untuk mematikan). Kode menggunakan `Area2D` dan sinyal `body_entered`/`body_exited` untuk mendeteksi keberadaan pemain.
* **Implementasi Audio Feedback**:
Saat pemain menekan tombol interaksi, game memberikan *feedback* instan berupa musik yang mulai berputar atau berganti. Selain itu, muncul elemen UI (Label) yang memberitahu judul lagu yang sedang diputar menggunakan sistem `Tween` untuk efek *fade-out*.
* **Sistem Audio Posisional (Poin Plus)**:
Dengan menggunakan `AudioStreamPlayer2D` pada objek Radio, saya berhasil mengimplementasikan audio yang volumenya mengecil saat pemain menjauh, sesuai dengan saran eksplorasi tingkat lanjut pada tutorial.

---

#### **Daftar Referensi**

**Aset Musik & Audio:**

* **Monkeys Spinning Monkeys** oleh Kevin MacLeod: [Link Incompetech](https://incompetech.com/) (Licensed under CC BY 3.0).
* **Daisy** oleh Sakura Girl: [Link Soundcloud](https://soundcloud.com/sakuragirl_official).
* **SFX Teleport**: Rekaman mandiri menggunakan Audacity.
* **Pak Vramroro**: [Kessoku Band](https://www.youtube.com/watch?v=2p2WBAc3ZQ4)
* **Diantara Ku Dan Sawit ( Mejikuhibiniu Parody )**: [Muraqa](https://www.youtube.com/watch?v=i2JQMDgNOa8&list=RDi2JQMDgNOa8&start_radio=1)

**Referensi Video & Dokumentasi:**

1. **Tutorial Sistem Interaksi**: [How to make an INTERACT SYSTEM in Godot 4](https://www.youtube.com/watch?v=pQINWFKc9_k) - Menjadi acuan dasar logika deteksi area pemain.
2. **Manajemen Audio**: [Godot 4 AudioStreamPlayer2D Tutorial](https://www.youtube.com/watch?v=2p2WBAc3ZQ4) - Referensi untuk pengaturan *attenuation* (penurunan volume berdasarkan jarak).
3. **Sistem Playlist & UI**: [Music Player with Playlist in Godot](https://www.youtube.com/watch?v=i2JQMDgNOa8&list=RDi2JQMDgNOa8&start_radio=1) - Acuan untuk logika perpindahan index pada array musik.
4. **Sistem Tween (Godot 4)**: Dokumentasi resmi Godot mengenai `create_tween()` untuk membuat notifikasi lagu yang memudar (*fade-out*).
5. **Generasi Aset**: Bantuan AI Gemini untuk pembuatan kerangka dasar spritesheet Radio sesuai spesifikasi 32x32 piksel.

---
</details>
