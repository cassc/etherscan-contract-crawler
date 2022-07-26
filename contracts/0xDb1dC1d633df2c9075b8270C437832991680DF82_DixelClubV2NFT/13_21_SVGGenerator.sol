// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.13;

import "base64-sol/base64.sol";
import "./lib/ColorUtils.sol";
import "./Constants.sol";

/**
* @title Dixel SVG image generator
*/
abstract contract SVGGenerator is Constants {

    // Using paths for each palette color (speed: 700-2300 / size: 1-5KB)
    // - pros: faster average speed, smaller svg size (over 50%)
    // - cons: slower worst-case speed


    // NOTE: viewBox -0.5 on top to prevent top side crop issue
    // ref: https://codepen.io/shshaw/post/vector-pixels-svg-optimization-animation-and-understanding-path-data#crazy-pants-optimization-4

    // NOTE: viewbox height 23.999 & preserveAspectRatio="none" to prevent gpas between shapes when it's resized to an indivisible dimensions (e.g. 480x480 -> fine, but 500x500 shows gaps)
    // ref: https://codepen.io/sydneyitguy/pen/MWVgOjG
    string private constant HEADER = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -0.5 24 23.999" width="960" height="960" preserveAspectRatio="none" shape-rendering="crispEdges">';
    string private constant FOOTER = '</svg>';

    function _generateSVG(uint24[PALETTE_SIZE] memory palette, uint8[PIXEL_ARRAY_SIZE] memory pixels) internal pure returns (string memory) {
        string[PALETTE_SIZE] memory paths;

        for (uint256 y; y < CANVAS_SIZE;) {
            uint256 prev = pixels[y * CANVAS_SIZE / 2] & 15; // prev pixel color. see comment below. x=0 so no shifting needed.
            paths[prev] = string(abi.encodePacked(paths[prev], "M0 ", ColorUtils.uint2str(y)));
            uint256 width = 1;

            for (uint256 x = 1; x < CANVAS_SIZE;) {
                /*
                    Pixels array: we're packing 2 pixels into each uint8.
                    So pixels[y * CANVAS_SIZE/2 + x/2] contains pixels (x,y) and (x+1,y).
                    The 4 rightmost bits are (x,y), so to extract that value we mask pixels[y * CANVAS_SIZE/2 + x/2] with 15 ("00001111").
                    The 4 leftmost bits are (x+1,y), so to extract that value we shift pixels[y * CANVAS_SIZE/2 + x/2]
                        4 places to the right, and then mask it with 15 ("00001111").
                 */
                uint256 current = (pixels[y * CANVAS_SIZE/2 + x/2] >> (4*(x%2))) & 15; // current pixel color.

                if (prev == current) {
                    width++;
                } else {
                    paths[prev] = string(abi.encodePacked(paths[prev], "h", ColorUtils.uint2str(width)));
                    width = 1;

                    paths[current] = string(abi.encodePacked(paths[current], "M", ColorUtils.uint2str(x), " ", ColorUtils.uint2str(y)));
                }

                if (x == CANVAS_SIZE - 1) {
                    paths[current] = string(abi.encodePacked(paths[current], "h", ColorUtils.uint2str(width)));
                }

                prev = current;

                unchecked {
                    ++x;
                }
            }
            unchecked {
                ++y;
            }
        }

        string memory joined;
        for (uint256 i; i < PALETTE_SIZE;) {
            if (bytes(paths[i]).length > 0) {
                joined = string(abi.encodePacked(joined, '<path stroke="#', ColorUtils.uint2hex(palette[i]), '" d="', paths[i], '"/>'));
            }
            unchecked {
                ++i;
            }
        }

        return string(abi.encodePacked(HEADER, joined, FOOTER));
    }

    // Using block-stacking approach with color variables (speed: ~1500 / size: ~8.5KB)
    // - pros: constant speed & svg size, faster worst-case speed
    // - cons: slower average speed, bigger svg size

    /* DEPRECATED in favor of the solution above
    string private constant HEADER = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMidYMid meet" viewBox="0 0 24 24" shape-rendering="crispEdges"><style>';
    string private constant FOOTER = '</style><defs><rect id="p" width="40" height="40"/><svg id="r"><use href="#p" fill="var(--a)"/><use href="#p" x="1" fill="var(--b)"/><use href="#p" x="2" fill="var(--c)"/><use href="#p" x="3" fill="var(--d)"/><use href="#p" x="4" fill="var(--e)"/><use href="#p" x="5" fill="var(--f)"/><use href="#p" x="6" fill="var(--g)"/><use href="#p" x="7" fill="var(--h)"/><use href="#p" x="8" fill="var(--i)"/><use href="#p" x="9" fill="var(--j)"/><use href="#p" x="10" fill="var(--k)"/><use href="#p" x="11" fill="var(--l)"/><use href="#p" x="12" fill="var(--m)"/><use href="#p" x="13" fill="var(--n)"/><use href="#p" x="14" fill="var(--o)"/><use href="#p" x="15" fill="var(--p)"/><use href="#p" x="16" fill="var(--q)"/><use href="#p" x="17" fill="var(--r)"/><use href="#p" x="18" fill="var(--s)"/><use href="#p" x="19" fill="var(--t)"/><use href="#p" x="20" fill="var(--u)"/><use href="#p" x="21" fill="var(--v)"/><use href="#p" x="22" fill="var(--w)"/><use href="#p" x="23" fill="var(--x)"/></svg></defs><use href="#r" class="a"/><use href="#r" y="1" class="b"/><use href="#r" y="2" class="c"/><use href="#r" y="3" class="d"/><use href="#r" y="4" class="e"/><use href="#r" y="5" class="f"/><use href="#r" y="6" class="g"/><use href="#r" y="7" class="h"/><use href="#r" y="8" class="i"/><use href="#r" y="9" class="j"/><use href="#r" y="10" class="k"/><use href="#r" y="11" class="l"/><use href="#r" y="12" class="m"/><use href="#r" y="13" class="n"/><use href="#r" y="14" class="o"/><use href="#r" y="15" class="p"/><use href="#r" y="16" class="q"/><use href="#r" y="17" class="r"/><use href="#r" y="18" class="s"/><use href="#r" y="19" class="t"/><use href="#r" y="20" class="u"/><use href="#r" y="21" class="v"/><use href="#r" y="22" class="w"/><use href="#r" y="23" class="x"/></svg>';
    bytes32 private constant CLASS = 'abcdefghijklmnopqrstuvwx'; // class names for each row, pixel (length must be equal to CANVAS_SIZE)

    function _generateSVG(uint24[PALETTE_SIZE] memory palette, uint8[TOTAL_PIXEL_COUNT] memory pixels) internal pure returns (string memory) {
        string memory joined;
        string[CANVAS_SIZE] memory styles;

        for (uint256 x = 0; x < CANVAS_SIZE; x++) {
            styles[x] = string(abi.encodePacked(styles[x], '.', CLASS[x], '{'));

            for (uint256 y = 0; y < CANVAS_SIZE; y++) {
                styles[x] = string(abi.encodePacked(styles[x], '--', CLASS[y], ':#', ColorUtils.uint2hex(palette[pixels[x * CANVAS_SIZE + y]]), ';'));
            }

            styles[x] = string(abi.encodePacked(styles[x], '}'));
            joined = string(abi.encodePacked(joined, styles[x]));
        }

        return string(abi.encodePacked(HEADER, joined, FOOTER));
    }
    */

    function _generateBase64SVG(uint24[PALETTE_SIZE] memory palette, uint8[PIXEL_ARRAY_SIZE] memory pixels) internal pure returns (string memory) {
        return string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(_generateSVG(palette, pixels)))));
    }
}