// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

enum Shape {
    NO_SHAPE,
    PEAR,
    ROUND,
    OVAL,
    CUSHION
}

enum Grade {
    NO_GRADE,
    GOOD,
    VERY_GOOD,
    EXCELLENT
}

enum Clarity {
    NO_CLARITY,
    VS2,
    VS1,
    VVS2,
    VVS1,
    IF,
    FL
}

enum Fluorescence {
    NO_FLUORESCENCE,
    FAINT,
    NONE
}

enum Color {
    NO_COLOR,
    K,
    L,
    M,
    N,
    O,
    P,
    Q,
    R,
    S,
    T,
    U,
    V,
    W,
    X,
    Y,
    Z
}

struct Certificate {
    uint64 number;
    uint32 date;
    uint16 length;
    uint16 width;
    uint16 depth;
    uint8 points;
    Clarity clarity;
    Color color;
    Color toColor;
    Grade cut;
    Grade symmetry;
    Grade polish;
    Fluorescence fluorescence;
    Shape shape;
}