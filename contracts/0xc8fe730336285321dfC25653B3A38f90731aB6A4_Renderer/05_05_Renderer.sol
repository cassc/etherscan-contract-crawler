// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./Base64.sol";
import "./IRenderer.sol";

contract Renderer is IRenderer {
    using Strings for uint256;

    string constant JSON_PROTOCOL_URI = "data:application/json;base64,";
    string constant SVG_PROTOCOL_URI = "data:image/svg+xml;base64,";

    bytes16 constant HEX_SYMBOLS = "0123456789abcdef";
    uint256 constant LINE_WIDTH = 30;
    // string constant HEAD = '<?xml version="1.0" encoding="UTF-8" standalone="no"?>';
    string constant SVG_START =
        '<svg viewBox="0 0 888 888" width="888" height="888" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">';
    string constant SVG_END = "</svg>";
    string constant STYLE = "<style>.h0{fill:#fff} .h1{fill:#000}</style>";

    string constant BACKGROUND =
        '<rect class="h0" x="0" y="0" width="888" height="888" />';

    string constant TITLE_START =
        '<text x="444" y="140" class="h1" font-family="monospace" font-size="28px" opacity=".5" text-anchor="middle">';
    string constant EDITION_START =
        '<text x="444" y="180" class="h1" font-family="monospace" font-size="20px" opacity=".5" text-anchor="middle">';
    string constant TEXT_END = "</text>";

    string constant AMULET_START =
        '<text class="h1" x="444" y="280" font-family="serif" font-size="45px" text-anchor="middle">';
    string constant LINE_START = '<tspan x="444" dy="1.5em">';
    string constant LINE_END = "</tspan>";

    function _getScore(uint256 hash) internal pure returns (uint32, uint32) {
        uint256 maxLen = 0;
        uint256 len = 0;
        uint256 maxStart = 0;
        uint256 start = 0;
        uint256 nibble = 64;
        for (; hash > 0; hash >>= 4) {
            if (hash & 0xf == 8) {
                len += 1;
                if (len > maxLen) {
                    maxLen = len;
                    maxStart = start;
                }
            } else {
                len = 0;
                start = nibble - 1;
            }
            nibble--;
        }
        return (uint32(maxLen), uint32(maxStart - maxLen));
    }

    function _renderAmulet(
        bytes memory amulet
    ) internal pure returns (bytes memory) {
        // Generate the SVG for the amulet, first we need to format it.
        bytes memory svgAmulet = bytes(AMULET_START);
        bytes memory line = new bytes(64);
        uint256 start;
        uint256 end;
        uint256 delta;
        uint256 i;
        for (; i < amulet.length; i++) {
            line[i - delta] = amulet[i];
            if (amulet[i] == " " || amulet[i] == "\n") {
                end = i;
            }
            if (i - start > LINE_WIDTH || amulet[i] == "\n") {
                // Truncate the size of the array to the length of the line because yolo
                assembly {
                    mstore(line, sub(add(end, 1), start))
                }
                svgAmulet = abi.encodePacked(
                    svgAmulet,
                    LINE_START,
                    line,
                    LINE_END
                );
                start = end + 1;
                i = start;
                delta = start;
                line = new bytes(64);
                line[i - delta] = amulet[i];
            }
        }
        end = i;
        assembly {
            mstore(line, sub(end, start))
        }
        svgAmulet = abi.encodePacked(svgAmulet, LINE_START, line, LINE_END);
        return abi.encodePacked(svgAmulet, TEXT_END);
    }

    function _renderHash(
        uint256 hash,
        uint256 score,
        uint256 startNibble
    ) internal pure returns (bytes memory) {
        // Generate the hash representation
        bytes memory svgHash;
        for (uint256 row = 0; row < 8; row++) {
            for (uint256 col = 0; col < 8; col++) {
                uint256 pos = row * 8 + col;
                uint256 nibble = (hash >> (252 - pos * 4)) & 0xf;
                uint256 x = 324 + col * 30;
                uint256 y = 580 + row * 30;
                uint256 hx = x + 15;
                uint256 hy = y + 15;
                uint256 opacity = 2e5 + (nibble * 1e6) / 64;
                if (pos >= startNibble && pos < startNibble + score) {
                    opacity = 888;
                } else {
                    opacity = 2e5 + (nibble * 1e6) / 128;
                }
                svgHash = abi.encodePacked(
                    svgHash,
                    '<text opacity="0.',
                    opacity.toString(),
                    '" class="h1" x="',
                    hx.toString(),
                    '" y="',
                    hy.toString(),
                    '" font-family="monospace" dominant-baseline="central" text-anchor="middle" font-size="20px">',
                    HEX_SYMBOLS[nibble],
                    TEXT_END
                );
            }
        }
        return svgHash;
    }

    function _render(
        bytes memory title,
        bytes memory edition,
        bytes memory amulet,
        uint hash,
        uint score,
        uint startNibble
    ) internal pure returns (bytes memory) {
        bytes memory svgComment = abi.encodePacked(
            "<!-- Original poem:\n",
            amulet,
            "\n-->"
        );

        bytes memory svgTitle = abi.encodePacked(TITLE_START, title, TEXT_END);
        bytes memory svgEdition = abi.encodePacked(
            EDITION_START,
            edition,
            TEXT_END
        );

        return
            abi.encodePacked(
                svgComment,
                SVG_START,
                STYLE,
                BACKGROUND,
                svgTitle,
                svgEdition,
                _renderAmulet(amulet),
                _renderHash(hash, score, startNibble),
                SVG_END
            );
    }

    function _escapeString(
        string memory text
    ) internal pure returns (bytes memory) {
        bytes memory bText = bytes(text);
        bytes memory escapedText;
        for (uint256 c = 0; c < bText.length; c++) {
            bytes1 char = bText[c];
            if (char == 0x0a) {
                escapedText = bytes.concat(escapedText, "\\n");
            } else {
                escapedText = bytes.concat(escapedText, char);
            }
        }
        return escapedText;
    }

    function _getDescriptionAndAttributes(
        uint score,
        string calldata amulet,
        string calldata title
    )
        internal
        pure
        returns (bytes memory description, bytes memory attributes)
    {
        bytes memory rarity = "common";
        if (score == 5) {
            rarity = "uncommon";
        } else if (score == 6) {
            rarity = "rare";
        } else if (score == 7) {
            rarity = "epic";
        } else if (score == 8) {
            rarity = "legendary";
        } else if (score == 9) {
            rarity = "mythic";
        } else if (score > 9) {
            rarity = "beyond mythic";
        }

        description = abi.encodePacked(
            "```\\n",
            _escapeString(amulet),
            "\\n```",
            "\\n\\n# About this amulet\\nThis is an amulet, a short poem with a lucky SHA-256 hash, explained [here](https://text.bargains/).\\n\\nThis poem's rarity is ",
            rarity,
            "."
        );

        attributes = abi.encodePacked(
            '"attributes":[',
            '{"display_type":"number","trait_type":"Score","value":',
            score.toString(),
            "},",
            '{"trait_type":"Rarity","value":"',
            rarity,
            '"},',
            '{"trait_type":"Collection","value":"',
            title,
            '"}',
            "]"
        );
    }

    function tokenURI(
        uint256 amuletId,
        uint256 supply,
        string calldata title,
        string calldata amulet
    ) public pure returns (string memory) {
        bytes memory edition = abi.encodePacked(
            amuletId.toString(),
            " of ",
            uint256(supply).toString()
        );
        uint256 hash = uint256(sha256(bytes(amulet)));
        (uint256 score, uint256 startNibble) = _getScore(hash);

        bytes memory image = abi.encodePacked(
            SVG_PROTOCOL_URI,
            Base64.encode(
                _render(
                    bytes(title),
                    edition,
                    bytes(amulet),
                    hash,
                    score,
                    startNibble
                )
            )
        );

        (
            bytes memory description,
            bytes memory attributes
        ) = _getDescriptionAndAttributes(score, amulet, title);

        bytes memory json = abi.encodePacked(
            '{"name":"',
            title,
            ", ",
            edition,
            '",',
            '"description":"',
            description,
            '",',
            '"poem":"',
            _escapeString(amulet),
            '","image":"',
            image,
            '",',
            attributes,
            "}"
        );
        return string(abi.encodePacked(JSON_PROTOCOL_URI, Base64.encode(json)));
    }
}