module systems;

import std.math;
import std.range;
import std.random;
import std.algorithm;

import gfm.math;
import entitysysd;
import allegro5.allegro;
import allegro5.allegro_color;
import allegro5.allegro_primitives;

import common;
import events;
import entities;
import components;

class RenderSystem : System {
    private ALLEGRO_BITMAP* _spritesheet;

    this(ALLEGRO_BITMAP* spritesheet) {
        _spritesheet = spritesheet;
    }

    override void run(EntityManager em, EventManager events, Duration dt) {
        // store old transformation to restore later.
        ALLEGRO_TRANSFORM oldTrans;
        al_copy_transform(&oldTrans, al_get_current_transform());

        // holding optimizes multiple draws from the same spritesheet
        al_hold_bitmap_drawing(true);

        ALLEGRO_TRANSFORM trans;

        foreach (entity; em.entitiesWith!(Sprite, Transform)) {
            auto entityTrans = entity.component!Transform.allegroTransform;
            auto r = entity.component!Sprite.rect;

            // reset the current drawing transform
            al_identity_transform(&trans);

            // place the origin of the sprite at its center
            al_translate_transform(&trans, -r.width / 2, -r.height / 2);

            // apply the transform of the current entity
            al_compose_transform(&trans, &entityTrans);

            al_use_transform(&trans);

            al_draw_tinted_bitmap_region(_spritesheet,
                                         entity.component!Sprite.tint,
                                         r.min.x, r.min.y, r.width, r.height,
                                         0, 0,
                                         0);
        }

        al_hold_bitmap_drawing(false);

        // restore previous transform
        al_use_transform(&oldTrans);
    }
}

class MotionSystem : System {
    override void run(EntityManager em, EventManager events, Duration dt) {
        immutable time = dt.total!"msecs" / 1000f; // in seconds

        foreach (ent, trans, vel; em.entitiesWith!(Transform, Velocity)) {
            trans.pos += vel.linear * time;
            trans.angle += vel.angular * time;
        }
    }
}

class InputSystem : System, Receiver!AllegroEvent {
    private Entity _player;
    enum playerSpeed = 240;

    this(Entity player) {
        _player = player;
    }

    void receive(AllegroEvent ev) {
        assert(_player.valid);

        auto pos(ALLEGRO_EVENT ev) { return vec2f(ev.mouse.x, ev.mouse.y); }

        auto trans = _player.component!Transform;
        auto vel = _player.component!Velocity;

        switch (ev.type) {
            case ALLEGRO_EVENT_KEY_DOWN:
                switch (ev.keyboard.keycode) {
                    case ALLEGRO_KEY_W:
                        vel.linear.y = -playerSpeed;
                        break;
                    case ALLEGRO_KEY_S:
                        vel.linear.y = playerSpeed;
                        break;
                    case ALLEGRO_KEY_A:
                        vel.linear.x = -playerSpeed;
                        break;
                    case ALLEGRO_KEY_D:
                        vel.linear.x = playerSpeed;
                        break;
                    case ALLEGRO_KEY_J:
                        _player.component!Loadout.weapons[0].firing = true;
                        _player.component!Loadout.weapons[1].firing = false;
                        break;
                    case ALLEGRO_KEY_K:
                        _player.component!Loadout.weapons[0].firing = false;
                        _player.component!Loadout.weapons[1].firing = true;
                        break;
                    default:
                }
                break;
            case ALLEGRO_EVENT_KEY_UP:
                switch (ev.keyboard.keycode) {
                    case ALLEGRO_KEY_W:
                    case ALLEGRO_KEY_S:
                        vel.linear.y = 0;
                        break;
                    case ALLEGRO_KEY_A:
                    case ALLEGRO_KEY_D:
                        vel.linear.x = 0;
                        break;
                    case ALLEGRO_KEY_J:
                        _player.component!Loadout.weapons[0].firing = false;
                        break;
                    case ALLEGRO_KEY_K:
                        _player.component!Loadout.weapons[1].firing = false;
                        break;
                    default:
                }
                break;

            default:
        }
    }
}

class AnimationSystem : System {
    private enum maxFrame = 8;  // all animations have 8 frames

    override void run(EntityManager em, EventManager events, Duration dt) {
        foreach (ent, ani, sprite; em.entitiesWith!(Animator, Sprite)) {
            immutable elapsed = dt.total!"msecs" / 1000f;

            if (ani.run && (ani.countdown -= elapsed) < 0) {
                ani.countdown = ani.duration;
                ani.frame = (ani.frame + 1) % maxFrame;
            }

            sprite.rect = ani.start.translate(ani.offset * ani.frame);
        }
    }
}

class WeaponSystem : System {
    override void run(EntityManager em, EventManager events, Duration dt) {
        enum projectileSpeed = 600;

        foreach (ent, trans, loadout; em.entitiesWith!(Transform, Loadout)) {
            immutable elapsed = dt.total!"msecs" / 1000f;

            foreach(ref w ; loadout.weapons) {
                if ((w.countdown -= elapsed) < 0 && w.firing) {
                    w.countdown = w.fireDelay;
                    auto pos = vec2f(trans.pos.x + 10, trans.pos.y);
                    w.fire(pos, em);
                }
            }
        }
    }
}

/// Destroy an entity after a certain amount of time has elapsed
class DestroyAfterSystem : System {
    override void run(EntityManager em, EventManager events, Duration dt) {
        immutable time = dt.total!"msecs" / 1000f; // in seconds

        foreach (ent, dest; em.entitiesWith!DestroyAfter)
            if ((dest.duration -= time) < 0)
                ent.destroy();
    }
}

/// Decrease a sprite's alpha every frame.
class FadeSpriteSystem : System {
    override void run(EntityManager em, EventManager events, Duration dt) {
        immutable secs = dt.total!"msecs" / 1000f; // in seconds

        foreach (ent, sprite, fade; em.entitiesWith!(Sprite, FadeSprite))
            sprite.tint.a -= fade.alphaPerSec * secs;
    }
}

/// Create sprites behind a moving object to create a 'trail' effect.
class RenderTrailSystem : System {
    override void run(EntityManager em, EventManager events, Duration dt) {
        immutable time = dt.total!"msecs" / 1000f; // in seconds

        foreach (ent, trans, sprite, trail;
                 em.entitiesWith!(Transform, Sprite, RenderTrail))
        {
            if ((trail.countdown -= time) < 0) {
                auto e = em.create();
                e.register!Transform(trans.pos, trans.scale, trans.angle);
                e.register!Sprite(sprite.rect, 0, sprite.tint);
                e.register!FadeSprite(0.2);
                e.register!DestroyAfter(0.2);

                trail.countdown = trail.interval; // reset timer
            }
        }
    }
}
