//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./SVG.sol";
import "./Utils.sol";

// adapted from https://github.com/w1nt3r-eth/hot-chain-svg

library Renderer {
    uint256 internal constant size = 600;
    uint256 internal constant rowSpacing = size / 8;
    uint256 internal constant colSpacing = size / 14;
    uint256 internal constant MAX_R = colSpacing * 65 / 100;
    uint256 internal constant MIN_R = colSpacing * 3 / 10;
    uint256 internal constant maxDur = 60;
    uint256 internal constant minDur = 30;
    uint256 internal constant durRandomnessDiscord = 5; // (60 - 30) < 2^5

    function render(address addr) internal pure returns (string memory) {
        string memory logo;
        uint256 seed = uint256(uint160(addr));
        string memory color = utils.getHslColor(seed);
        uint8[5] memory xs = [5, 4, 3, 4, 5];
        uint256 y = rowSpacing * 2;
        for (uint256 i; i < 5; i++) {
            uint256 x = colSpacing * xs[i];
            for (uint256 j; j < (8 - xs[i]); j++) {
                logo = string.concat(logo, drawRandomOrb(x, y, color, seed = newSeed(seed)));
                x += colSpacing * 2;
            }
            y += rowSpacing;
        }

        return string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" width="',
            utils.uint2str(size),
            '" height="',
            utils.uint2str(size),
            '" style="background:#000000;font-family:sans-serif;fill:#fafafa;font-size:32">',
            logo,
            "</svg>"
        );
    }

    function randomR(uint256 seed) internal pure returns (uint256 r) {
        r = utils.bound(seed, MAX_R, MIN_R);
    }

    function randomDur(uint256 seed) internal pure returns (uint256 dur) {
        dur = utils.bound(seed, maxDur, minDur);
    }

    function newSeed(uint256 seed) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(seed)));
    }

    function drawRandomOrb(uint256 cx, uint256 cy, string memory color, uint256 seed)
        internal
        pure
        returns (string memory)
    {
        uint256 dur = randomDur(seed);
        uint256 r = randomR(seed >> durRandomnessDiscord);
        return drawOrb(cx, cy, r, dur, color);
    }

    function drawOrb(uint256 cx, uint256 cy, uint256 r, uint256 dur, string memory color)
        internal
        pure
        returns (string memory _values)
    {
        string memory animate;
        string memory durStr = string.concat(utils.uint2str(dur / 10), ".", utils.uint2str(dur % 10));
        string memory valStr = string.concat(
            utils.uint2str(r), "; ", utils.uint2str(MAX_R), "; ", utils.uint2str(MIN_R), "; ", utils.uint2str(r)
        );
        animate = svg.animate(
            string.concat(
                svg.prop("attributeName", "r"),
                svg.prop("dur", durStr),
                svg.prop("repeatCount", "indefinite"),
                svg.prop("calcMode", "paced"),
                svg.prop("values", valStr)
            )
        );
        _values = svg.circle(
            string.concat(
                svg.prop("cx", utils.uint2str(cx)),
                svg.prop("cy", utils.uint2str(cy)),
                svg.prop("r", utils.uint2str(r)),
                svg.prop("fill", color)
            ),
            animate
        );
    }
}