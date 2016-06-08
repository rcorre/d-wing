module weapon;

import std.math;

import gfm.math;
import entitysysd;

import common;
import components;

private void createBullet(EntityManager em, vec2f pos, float angle, float speed)
{
    auto ent = em.create();

    ent.register!Transform(pos, vec2f(1, 1), angle);
    ent.register!Velocity(vec2f(speed * cos(angle), speed * sin(angle)));
    ent.register!Sprite(SpriteRect.chainShot);
    ent.register!RenderTrail(0.01); // create a 'ghost' every 0.01s
    ent.register!DestroyAfter(3.0); // ensure it doesn't hang around forever
}

// used in loadout
abstract class Weapon {
    float fireDelay();
    void fire(vec2f pos, EntityManager em);

    float countdown = 0;
    bool firing;
}

class ChainGun : Weapon {
    private enum maxSpread = 4;
    private enum maxAngle = 0.04;

override:
    float fireDelay() { return 0.05; }

    void fire(vec2f pos, EntityManager em) {
        immutable offset = uniform(-maxSpread, maxSpread);
        immutable angle = uniform(-maxAngle, maxAngle);
        em.createBullet(pos + offset, angle, 1200);
    }
}

class SpreadGun : Weapon {
override:
    float fireDelay() { return 0.25; }

    void fire(vec2f pos, EntityManager em) {
        em.createBullet(pos, 0, 800);
        em.createBullet(pos, -PI / 8, 800);
        em.createBullet(pos, PI / 8, 800);
    }
}
