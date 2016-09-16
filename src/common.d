module common;

import gfm.math;

enum {
    screenW = 800,
    screenH = 600,
}

private auto spriteRect(int x, int y, int w, int h) {
    return box2i(x, y, x + w, y + h);
}

struct SpriteRect {
    static immutable player = spriteRect(0 * 16, 0 * 16, 2 * 16, 1 * 16);
    static immutable enemy  = spriteRect(2 * 16, 0 * 16, 2 * 16, 2 * 16);

    static immutable chainShot = spriteRect(0, 16, 16, 2);
    static immutable spreadShot = spriteRect(0, 18, 7, 2);
}
