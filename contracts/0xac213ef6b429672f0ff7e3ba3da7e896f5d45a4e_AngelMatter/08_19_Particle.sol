// SPDX-License-Identifier: UNLICENSE
pragma solidity 0.8.20;

import {Base64} from "../lib/solady/src/utils/Base64.sol";
import {LibString} from "../lib/solady/src/utils/LibString.sol";

library Particle {
    using LibString for uint8;
    using LibString for uint160;
    using LibString for uint256;

    function _upper() internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<svg height="250" width="250" xmlns="http://www.w3.org/2000/svg">',
                    "<defs>",
                    '<radialGradient id="myGradient">'
                )
            );
    }

    function _orbital(
        bytes32 seed,
        uint8 num
    ) internal pure returns (string memory) {
        string memory first = string(
            abi.encodePacked(
                '<stop offset="',
                (5 + num * 20).toString(),
                '%" stop-color="rgb(',
                uint8(seed[0 + (num * 6)]).toString(),
                ",",
                uint8(seed[1 + (num * 6)]).toString(),
                ",",
                uint8(seed[2 + (num * 6)]).toString(),
                ')" />'
            )
        );
        string memory second = string(
            abi.encodePacked(
                '<stop offset="',
                (15 + num * 20).toString(),
                '%" stop-color="rgb(',
                uint8(seed[3 + (num * 6)]).toString(),
                ",",
                uint8(seed[4 + (num * 6)]).toString(),
                ",",
                uint8(seed[5 + (num * 6)]).toString(),
                ')" />'
            )
        );
        return string(abi.encodePacked(first, second));
    }

    function _lower() internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "</radialGradient>",
                    "</defs>",
                    '<rect height="250" width="250" fill="#000"></rect>'
                )
            );
    }

    function _elements(bytes32 seed) internal pure returns (string memory) {
        string[16] memory elements = [
            "&#10696;",
            "&#9737;",
            "&#8853;",
            "&#128842;",
            "&#10023;",
            "&#9672;",
            "&#10070;",
            "&#10803;",
            "&#10040;",
            "&#10057;",
            "&#128779;",
            "&#9883;",
            "&#8258;",
            "&#9738;",
            "&#9854;",
            "&#8578;"
        ];

        string memory a = elements[uint8(seed[31]) & 15];
        string memory b = elements[(uint8(seed[31]) & 240) / 16];
        string memory c = elements[uint8(seed[30]) & 15];
        string memory d = elements[(uint8(seed[30]) & 240) / 16];

        return
            string(
                abi.encodePacked(
                    '<text fill="#ffffff" font-size="30" font-family="Verdana" x="32" y="42" text-anchor="middle">',
                    a,
                    "</text>",
                    '<text fill="#ffffff" font-size="30" font-family="Verdana" x="218" y="42" text-anchor="middle">',
                    b,
                    "</text>",
                    '<text fill="#ffffff" font-size="30" font-family="Verdana" x="32" y="228" text-anchor="middle">',
                    c,
                    "</text>",
                    '<text fill="#ffffff" font-size="30" font-family="Verdana" x="218" y="228" text-anchor="middle">',
                    d,
                    "</text>"
                )
            );
    }

    function _power() internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<circle cx="125" cy="125" r="100" fill="url(\'#myGradient\')" />',
                    "</svg>"
                )
            );
    }

    function _particle(bytes32 seed) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _upper(),
                    _orbital(seed, 0),
                    _orbital(seed, 1),
                    _orbital(seed, 2),
                    _orbital(seed, 3),
                    _orbital(seed, 4),
                    _lower(),
                    _elements(seed),
                    _power()
                )
            );
    }

    function _image(bytes32 seed) internal pure returns (string memory) {
        string memory image = _particle(seed);
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(bytes(image))
                )
            );
    }
}