// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {LibPRNG} from "solady/utils/LibPRNG.sol";
import {LibString} from "solady/utils/LibString.sol";

/// @title Adopt-a-Hyphen art
/// @notice A library for generating SVGs for {AdoptAHyphen}.
/// @dev For this library to be correct, all `_seed` values must be consistent
/// with every function in both {AdoptAHyphenArt} and {AdoptAHyphenMetadata}.
library AdoptAHyphenArt {
    using LibPRNG for LibPRNG.PRNG;
    using LibString for uint256;

    // -------------------------------------------------------------------------
    // Structs
    // -------------------------------------------------------------------------

    /// @notice The traits that make up a Hyphen Guy.
    /// @param head Head trait, a number in `[0, 3]`. Equal chances.
    /// @param eye Eye trait, a number in `[0, 16]`. Equal chances.
    /// @param hat Hat trait, a number in `[0, 14]`. 25% chance of being `0`,
    /// which indicates no hat trait. Equal chances amongst the other hats.
    /// @param arm Arm trait, a number in `[0, 4]`. Equal chances.
    /// @param body Body trait, a number in `[0, 2]`. Equal chances.
    /// @param chest Chest trait, a number in `[0, 4]`. 50% chance of being `0`,
    /// which indicates no chest trait. Equal chances amongst the other chests.
    /// @param leg Leg trait, a number in `[0, 3]`. Equal chances.
    /// @param background Background trait, a number in `[0, 8]`. Equal chances.
    /// @param chaosBg Whether the background is made up of multiple background
    /// characters, or just 1. 25% chance of being true.
    /// @param intensity Number of positions (out of 253 (`23 * 11`)) to fill
    /// with a background character, a number in `[50, 200]`. 25% chance of
    /// being `252`, which indicates no variable intensity (every empty position
    /// would be filled). Equal chances amongst the other intensities.
    struct HyphenGuy {
        uint8 head;
        uint8 eye;
        uint8 hat;
        uint8 arm;
        uint8 body;
        uint8 chest;
        uint8 leg;
        uint8 background;
        bool chaosBg;
        uint8 intensity;
        bool inverted;
        uint8 color;
    }

    // -------------------------------------------------------------------------
    // Constants
    // -------------------------------------------------------------------------

    /// @notice Starting string for the SVG.
    /// @dev The `line-height` attribute for `pre` elements is set to `51px`
    /// because we want to fit in 11 lines into a `600 - 32 * 2 + 12` = 548px
    /// tall container. At 32px, the Martian Mono Extra Bold font has a width of
    /// 22.4px and a height of 38.5px. Additionally, we want to fit 11 lines
    /// with 23 characters each into a 600px square container with 32px padding
    /// on each side. Martian Mono comes with an overhead of 12px above each
    /// character, and 0px on either side, so effectively, we want to fit in
    /// `22.4px/character * 11 characters` into a `600 - 32 * 2 + 12` = 548px
    /// tall container, and `38.5px/character * 23 characters` into a
    /// `600 - 32 * 2` = 536px wide container. Therefore, we calculate 51px for
    /// the `line-height` property:
    /// `38.5 + (548 - 38.5 * 11) / (11 - 1) = 50.95 ≈ 51`. We round to `51`
    /// because Safari doesn't support decimal values for `line-height`, so
    /// technically, the text is off by `0.05 * 23` = 1.15px. Similarly, we
    /// calculate 0.945 for the `letter-spacing` property:
    /// `(536 - 23 * 22.4) / 22 ≈ 0.945`. We set these properties on the `pre`
    /// element.
    string constant SVG_START =
        '<svg xmlns="http://www.w3.org/2000/svg" width="600" height="600" viewB'
        'ox="0 0 600 600"><style>@font-face{font-family:A;src:url(data:font/wof'
        "f2;utf-8;base64,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)}pre{font-family:A;font-s"
        "ize:32px;text-align:center;margin:0;letter-spacing:0.945px;line-height"
        ":51px}@supports (color:color(display-p3 1 1 1)){.z{color:oklch(79.59% "
        "0.042 250.64)!important}.y{color:oklch(60.59% 0.306 309.33)!important}"
        ".x{color:oklch(69.45% 0.219 157.46)!important}.w{color:oklch(75.22% 0."
        "277 327.48)!important}.v{color:oklch(77.86% 0.16 226.017)!important}.u"
        "{color:oklch(74.3% 0.213 50.613)!important}.t{color:oklch(61.52% 0.224"
        " 256.099)!important}.s{color:oklch(62.61% 0.282 29.234)!important}}</s"
        "tyle><path ";

    /// @notice Ending string for the SVG.
    string constant SVG_END = "</pre></foreignObject></svg>";

    /// @notice Characters corresponding to the `head` trait's left characters.
    bytes32 constant HEADS_LEFT = "|[({";

    /// @notice Characters corresponding to the `head` trait's right characters.
    bytes32 constant HEADS_RIGHT = "|])}";

    /// @notice Characters corresponding to the `eye` trait's characters.
    bytes32 constant EYES = "\"#$'*+-.0=OTX^oxz";

    /// @notice Characters corresponding to the `hat` trait's characters.
    /// @dev An index of 0 corresponds to no hat trait, so the character at
    /// index 0 can be anything, but we just made it a space here.
    /// @dev If the hat character is `&` (i.e. index of `5`), then it must be
    /// drawn in its entity form, i.e. `&amp;`.
    bytes32 constant HATS = " !#$%&'*+-.=@^~";

    /// @notice Characters corresponding to the `arm` trait's left characters.
    /// @dev If the arm character is `<` (i.e. index of `1`), then it must be
    /// drawn in its entity form, i.e. `&lt;`.
    bytes32 constant ARMS_LEFT = "/<~J2";

    /// @notice Characters corresponding to the `arm` trait's right characters.
    /// @dev If the arm character is `>` (i.e. index of `1`), then it must be
    /// drawn in its entity form, i.e. `&gt;`.
    bytes32 constant ARMS_RIGHT = "\\>~L7";

    /// @notice Characters corresponding to the `body` trait's left characters.
    bytes32 constant BODIES_LEFT = "[({";

    /// @notice Characters corresponding to the `body` trait's right characters.
    bytes32 constant BODIES_RIGHT = "])}";

    /// @notice Characters corresponding to the `chest` trait's characters.
    /// @dev An index of 0 corresponds to no chest trait, so the character at
    /// index 0 can be anything, but we just made it a space here.
    bytes32 constant CHESTS = "  :*=.";

    /// @notice Characters corresponding to the `leg` trait's left characters.
    bytes32 constant LEGS_LEFT = "|/|/";

    /// @notice Characters corresponding to the `leg` trait's right characters.
    bytes32 constant LEGS_RIGHT = "||\\\\";

    /// @notice Characters corresponding to the `background` trait's characters.
    /// @dev If the background character is `\` (i.e. index of `6`), then it
    /// must be escaped properly in JSONs, i.e. `\\\\`.
    bytes32 constant BACKGROUNDS = "#*+-/=\\|.";

    /// @notice Characters for the last few characters in the background that
    /// spell out ``CHAIN''.
    /// @dev The character at index 0 can be anything, but we just made it `N`
    /// here.
    bytes32 constant CHAIN_REVERSED = "NIAHC";

    /// @notice Bitpacked integer of 32-bit words containing 24-bit colors.
    /// @dev The first 8 bits in each word are unused, but we made each word
    /// 32-bit so we can calculate the bit index via `<< 5`, rather than `* 24`.
    uint256 constant COLORS =
        0xA9BFD700AD43ED0000BA7300FE63FF0000C9FF00FF8633000080FF00FE0000;

    /// @notice Utility string for converting targetting classes that provide
    /// p3 color support (see classes `s` through `z` in `SVG_START`'s `<style>`
    /// block).
    bytes32 constant COLOR_CLASSES = "stuvwxyz";

    // -------------------------------------------------------------------------
    // `render`
    // -------------------------------------------------------------------------

    /// @notice Renders a Hyphen Guy SVG.
    /// @param _seed Seed to select traits for the Hyphen Guy.
    /// @return SVG string representing the Hyphen Guy.
    function render(uint256 _seed) internal pure returns (string memory) {
        // Initialize PRNG.
        LibPRNG.PRNG memory prng = LibPRNG.PRNG(_seed);

        // The Hyphen Guy.
        HyphenGuy memory hyphenGuy;

        // Select traits from `prng`.
        hyphenGuy.head = uint8(prng.state & 3); // 4 heads (2 bits)
        prng.state >>= 2;
        hyphenGuy.eye = uint8(prng.state % 17); // 17 eyes (5 bits)
        prng.state >>= 5;
        hyphenGuy.hat = uint8( // 25% chance + 14 hats (2 + 4 = 6 bits)
            prng.state & 3 == 0 ? 0 : 1 + ((prng.state >> 2) % 14)
        );
        prng.state >>= 6;
        hyphenGuy.arm = uint8(prng.state % 5); // 5 arms (3 bits)
        prng.state >>= 3;
        hyphenGuy.body = uint8(prng.state % 3); // 3 bodies (2 bits)
        prng.state >>= 2;
        hyphenGuy.chest = uint8(
            prng.state & 1 == 0 ? 0 : 1 + ((prng.state >> 1) % 5)
        ); // 50% chance + 5 chests (1 + 3 = 4 bits)
        prng.state >>= 4;
        hyphenGuy.leg = uint8(prng.state & 3); // 4 legs (2 bits)
        prng.state >>= 2;
        hyphenGuy.background = uint8(prng.state % 9); // 9 backgrounds (4 bits)
        prng.state >>= 4;
        hyphenGuy.chaosBg = prng.state & 3 == 0; // 25% chance (2 bits)
        prng.state >>= 2;
        hyphenGuy.intensity = uint8(
            prng.state & 3 == 0 ? 50 + ((prng.state >> 2) % 151) : 252
        ); // 25% chance + 151 intensities (2 + 8 = 10 bits)
        prng.state >>= 10;
        hyphenGuy.inverted = prng.state & 7 == 0; // 12.5% chance (3 bits)
        prng.state >>= 3;
        hyphenGuy.color = uint8(prng.state & 7); // 8 colors (3 bits)

        // Get the next state in the PRNG.
        prng.state = prng.next();

        // `bitmap` has `0`s where the index corresponds to a Hyphen Guy
        // character, and `1` where not. We use this to determine whether to
        // render a Hyphen Guy character or a background character. i.e. it
        // looks like the following:
        //                        11111111111111111111111
        //                        11111111111111111111111
        //                        11111111111111111111111
        //                        11111111111111111111111
        //                        11111111100000111111111
        //                        11111111100100111111111
        //                        11111111100100111111111
        //                        11111111111111111111111
        //                        11111111111111111111111
        //                        11111111111111111111111
        //                        11111111111111111111111
        // By default, `bitmap` has `1`s set in the positions for hat and chest
        // characters. In the following `assembly` block, we determine whether a
        // hat or chest exists and `XOR` the relevant parts to transform the
        // bitmap.
        uint256 bitmap = 0x1FFFFFFFFFFFFFFFFFFFFFFFFF07FFFE4FFFFC9FFFFFFFFFFFFFFFFFFFFFFFFF;
        uint8 hat = hyphenGuy.hat;
        uint8 chest = hyphenGuy.chest;
        assembly {
            // Equivalent to
            // `bitmap ^= (((hat != 0) << 172) | ((chest != 0) << 126))`. We
            // flip the bit corresponding to the position of the chest if there
            // exists a chest trait because we don't want to draw both a
            // background character and the chest character.
            bitmap := xor(
                bitmap,
                or(shl(172, gt(hat, 0)), shl(126, gt(chest, 0)))
            )
        }

        // Here, we initialize another bitmap to determine whether to render a
        // space character or a background character when we're not observing a
        // `hyphenGuy` character position. Since we want to render as many
        // characters in the background as equals the intensity value, we can:
        //     1. Instantiate a 253-bit long bitmap.
        //     2. Set the first `intensity` bits to `1`, and `0` otherwise.
        //     3. Shuffle the bitmap.
        // Then, by reading the bits at each index, we can determine whether to
        // render a space character (i.e. empty) or a background character. We
        // begin by instantiating an array of 253 `uint256`s, each with a single
        // `1` bit set to make use of `LibPRNG.shuffle`.
        uint256[] memory bgBitmapBits = new uint256[](253);
        for (uint256 i; i <= hyphenGuy.intensity; ) {
            bgBitmapBits[i] = 1;
            unchecked {
                ++i;
            }
        }

        // Shuffle the array if intensity mode.
        if (hyphenGuy.intensity < 252) prng.shuffle(bgBitmapBits);

        uint256 bgBitmap;
        for (uint256 i; i < 253; ) {
            // `intensity >= 252` implies `intenseBg = true`
            bgBitmap <<= 1;
            bgBitmap |= bgBitmapBits[i];
            unchecked {
                ++i;
            }
        }
        prng.state = prng.next();

        uint256 row;
        uint256 col;
        // The string corresponding to the characters of the contents of the
        // background `<text>` element.
        string memory bgStr = "";
        // The string corresponding to the characters of the contents of the
        // Hyphen Guy `<text>` element. We generate the entire first row here.
        string memory charStr = string.concat(
            "  ", // Start with 2 spaces for positioning.
            // If the hat character is `&`, we need to draw it as
            // its entity form.
            hyphenGuy.hat != 5
                ? string(abi.encodePacked(HATS[hyphenGuy.hat]))
                : "&amp;",
            hyphenGuy.hat != 0 ? "" : " ",
            "  \n"
        );
        // Iterate through the positions in reverse order. Note that the last
        // character (i.e. the one that contains ``N'' from ``CHAIN'') is not
        // drawn, and it must be accounted for after the loop.
        for (uint256 i = 252; i != 0; ) {
            assembly {
                row := div(i, 11)
                col := mod(i, 23)
            }

            // Add word characters (i.e. ``ON'' and ``CHAIN'').
            if (i == 252) bgStr = string.concat(bgStr, "O");
            else if (i == 251) bgStr = string.concat(bgStr, "N");
            else if (i < 5) {
                bgStr = string.concat(
                    bgStr,
                    string(abi.encodePacked(CHAIN_REVERSED[i]))
                );
            } else if ((bitmap >> i) & 1 == 0) {
                // Is a Hyphen Guy character.
                // Since there's a Hyphen Guy character that'll be drawn, the
                // background character in the same position must be empty.
                bgStr = string.concat(bgStr, " ");

                // Generate the Hyphen Guy by drawing rows of characters. Note
                // that we've already passed the check for whether a chest
                // character exists and applied it to the bitmap accordingly, so
                // we can safely draw the chest character here--if no chest
                // piece exists, a background character will be drawn anyway
                // because it wouldn't pass the `(bitmap >> i) & 1 == 0` check.
                if (i == 151) {
                    charStr = string.concat(
                        charStr,
                        string(abi.encodePacked(HEADS_LEFT[hyphenGuy.head])),
                        string(abi.encodePacked(EYES[hyphenGuy.eye])),
                        "-",
                        string(abi.encodePacked(EYES[hyphenGuy.eye])),
                        string(abi.encodePacked(HEADS_RIGHT[hyphenGuy.head])),
                        "\n"
                    );
                } else if (i == 128) {
                    charStr = string.concat(
                        charStr,
                        // If the arm character is `<`, we need to draw it as
                        // its entity form.
                        hyphenGuy.arm != 1
                            ? string(abi.encodePacked(ARMS_LEFT[hyphenGuy.arm]))
                            : "&lt;",
                        string(abi.encodePacked(BODIES_LEFT[hyphenGuy.body]))
                    );
                    {
                        charStr = string.concat(
                            charStr,
                            string(abi.encodePacked(CHESTS[hyphenGuy.chest])),
                            string(
                                abi.encodePacked(BODIES_RIGHT[hyphenGuy.body])
                            ),
                            // If the arm character is `>`, we need to draw it
                            // as its entity form.
                            hyphenGuy.arm != 1
                                ? string(
                                    abi.encodePacked(ARMS_RIGHT[hyphenGuy.arm])
                                )
                                : "&gt;",
                            "\n"
                        );
                    }
                } else if (i == 105) {
                    charStr = string.concat(
                        charStr,
                        "_",
                        string(abi.encodePacked(LEGS_LEFT[hyphenGuy.leg])),
                        " ",
                        string(abi.encodePacked(LEGS_RIGHT[hyphenGuy.leg])),
                        "_"
                    );
                }
            } else if ((bgBitmap >> i) & 1 != 0) {
                // We make use of the `bgBitmap` generated earlier from the
                // intensity value here. If the check above passed, it means a
                // background character must be drawn here.
                bgStr = string.concat(
                    bgStr,
                    string(
                        abi.encodePacked(
                            BACKGROUNDS[
                                // Select a random background if `chaosBg` is
                                // true.
                                hyphenGuy.chaosBg
                                    ? prng.state % 9
                                    : hyphenGuy.background
                            ]
                        )
                    )
                );
                // We need to generate a new random number for the next
                // potentially-random character.
                prng.state = prng.next();
            } else {
                // Failed all checks. Empty background character.
                bgStr = string.concat(bgStr, " ");
            }

            // Draw a newline character if we've reached the end of a row.
            if (col == 0) bgStr = string.concat(bgStr, "\n");
            unchecked {
                --i;
            }
        }

        string memory colorHexString = string.concat(
            "#",
            ((COLORS >> (hyphenGuy.color << 5)) & 0xFFFFFF).toHexStringNoPrefix(
                3
            )
        );

        return
            string.concat(
                SVG_START,
                hyphenGuy.inverted
                    ? string.concat(
                        'class="',
                        string(
                            abi.encodePacked(COLOR_CLASSES[hyphenGuy.color])
                        ),
                        '" '
                    )
                    : "",
                'd="M0 0h600v600H0z" fill="',
                hyphenGuy.inverted ? colorHexString : "#FFF",
                // `x` is `32` because we want a left padding of 32px. `y` is
                // `20` because the Martian Mono font has an overhead of 12px,
                // and we want a top padding of 32px. Thus, by setting it to
                // `32 - 12` = 20px, we align the top of the letters with 32px
                // down from the top of the SVG. `width` is `536` because we
                // want left/right padding of 32px: `600 - 32*2 = 536`. Finally,
                // `height` is `561` because we have 11 lines, and each line is
                // 51 pixels tall: `11 * 51 = 561`.
                '"/><foreignObject x="32" y="20" width="536" height="561"><pre '
                'style="color:rgba(0,0,0,0.05)" xmlns="http://www.w3.org/1999/x'
                'html">',
                bgStr,
                // Recall that ``N'' was not accounted for in the loop because
                // we didn't look at index 0, so we draw it here. `x` is `32`
                // for the same reason outlined in the previous comment. `y` is
                // `173` because the character starts 3 lines below the first
                // (`3 * 51 = 153`), and we have the same 20px overhead as
                // before, so `153 + 20 = 173`. `width` is `536` for the same
                // reason. Finally, `height` is `204` because the character is 4
                // lines tall, and each line is 51 pixels tall: `4 * 51 = 204`.
                'N</pre></foreignObject><foreignObject x="32" y="173" width="53'
                '6" height="204"><pre',
                hyphenGuy.inverted
                    ? ""
                    : string.concat(
                        ' class="',
                        string(
                            abi.encodePacked(COLOR_CLASSES[hyphenGuy.color])
                        ),
                        '"'
                    ),
                ' style="color:',
                hyphenGuy.inverted ? "#FFF" : colorHexString,
                '" xmlns="http://www.w3.org/1999/xhtml">',
                charStr,
                SVG_END
            );
    }
}