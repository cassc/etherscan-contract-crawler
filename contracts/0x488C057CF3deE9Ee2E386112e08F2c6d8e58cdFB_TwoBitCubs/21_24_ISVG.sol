// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ISVG image library interface
interface ISVG {

    /// Represents a color in RGB format with alpha
    struct Color {
        uint8 red;
        uint8 green;
        uint8 blue;
        uint8 alpha;
    }

    /// Represents a color type in an SVG image file
    enum ColorType {
        Fill, Stroke, None
    }
}