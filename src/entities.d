
module entities;

import std.conv;
import std.math;
import std.range;
import std.algorithm;

import dtiled;
import gfm.math;
import entitysysd;
import allegro5.allegro;
import allegro5.allegro_color;

import common;
import weapon;
import components;

public:
auto createPlayer(EntityManager em) {
    auto ent = em.create();

    ent.register!Transform(vec2f(400, 400));
    ent.register!Velocity();
    ent.register!Sprite(SpriteRect.player);

    auto loadout = ent.register!Loadout;
    loadout.weapons[0] = new ChainGun();
    loadout.weapons[1] = new SpreadGun();
    //ent.register!Animator(0.1f, SpriteRect.player, animationOffset);
    //ent.register!UnitCollider(box2f(0, 0, 16, 16)); // 16x16 box

    return ent;
}

auto createEnemy(EntityManager em, vec2f pos) {
    auto ent = em.create();

    ent.register!Transform(pos, vec2f(1, 1), PI);
    ent.register!Velocity();
    ent.register!Sprite(SpriteRect.enemy);
    ent.register!Collider(vec2i(SpriteRect.enemy.width,
                                SpriteRect.enemy.height));

    return ent;
}
