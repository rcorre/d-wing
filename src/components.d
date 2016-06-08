module components;

import std.typecons : Flag;

import gfm.math;
import entitysysd;
import allegro5.allegro;
import allegro5.allegro_color;

import weapon;

@component:

struct Transform {
    vec2f pos = [0,0];
    vec2f scale = [1,1];
    float angle = 0;

    /// Convert to an ALLEGRO_TRANSFORM.
    auto allegroTransform() {
        ALLEGRO_TRANSFORM trans;

        al_identity_transform(&trans);
        al_scale_transform(&trans, scale.x, scale.y);
        al_rotate_transform(&trans, angle);
        al_translate_transform(&trans, pos.x, pos.y);

        return trans;
    }
}

struct Sprite {
    box2i rect;
    int layer = 0;
    ALLEGRO_COLOR tint = ALLEGRO_COLOR(1,1,1,1);
}

struct Velocity {
    vec2f linear = [0,0];
    float angular = 0;
}

struct Animator {
    float duration, countdown;
    int frame;
    box2i start;
    vec2i offset;
    bool run;

    this(float duration, box2i start, vec2i offset) {
        this.duration = this.countdown = duration;
        this.start = start;
        this.offset = offset;
    }
}

struct Health {
    int amount;
}

struct RenderTrail {
    this(float interval) {
        this.interval = interval;
        this.countdown = interval;
    }

    float interval;
    float countdown;
}

struct FadeSprite {
    this(float duration) {
        alphaPerSec = 1 / duration;
    }

    float alphaPerSec;
}

struct DestroyAfter {
    float duration;
}

struct Loadout {
    Weapon[2] weapons;
}
