//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./SVG.sol";
import "./ICryptoPunksData.sol";
import {Base64} from "openzeppelin/utils/Base64.sol";
import {LibString} from "solmate/utils/LibString.sol";

contract OnChainPunkChecksRenderer {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    address public constant PUNKS_DATA_ADDRESS = address(0x16F5A35647D6F03D5D3da7b35409D65ba03aF3B2);

    string private constant DESCRIPTION =
        "Punk Checks are an homage to CryptoPunks and Jack Butcher\'s Checks. Each Punk Check is a unique rendering of a CryptoPunk using checks instead of pixels.";

    function tokenURI(uint256 punkId, uint256 t) public view returns (string memory) {
        require(t >= 1 && t <= 4, "Invalid version");
        string memory svgContents = renderSvg(punkId, t);
        string memory name = string.concat("Punk Checks #", LibString.toString(punkId));
        bytes memory s = abi.encodePacked(
            '{"name": "',
            name,
            '","description": "',
            DESCRIPTION,
            '","image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(svgContents)),
            '", "attributes": [',
            '{"trait_type": "Origin","value": "',
            t == 1 ? "CryptoPunks V1" : (t == 2 ? "CryptoPunks V2" : t == 3 ? "CryptoPunks OG" : "CryptoPunks Wannabe"),
            '"}]}'
        );
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(s))));
    }

    function renderSvg(uint256 punkId, uint256 t) public view returns (string memory) {
        bytes memory pixels = ICryptoPunksData(PUNKS_DATA_ADDRESS).punkImage(uint16(punkId));
        string memory checks;

        bytes memory buffer = new bytes(8);
        uint256 i;
        while (i < 576) {
            uint256 p = i * 4;
            unchecked {
                uint256 x = i % 24;
                uint256 y = i / 24;
                if (uint8(pixels[p + 3]) > 0) {
                    for (uint256 j = 0; j < 4; j++) {
                        uint8 value = uint8(pixels[p + j]);
                        buffer[j * 2 + 1] = _HEX_SYMBOLS[value & 0xf];
                        value >>= 4;
                        buffer[j * 2] = _HEX_SYMBOLS[value & 0xf];
                    }
                    checks = string.concat(
                        checks,
                        svg.el(
                            "use",
                            string.concat(
                                svg.prop("href", "#c"),
                                svg.prop("x", LibString.toString(160 + x * 40)),
                                svg.prop("y", LibString.toString(160 + y * 40)),
                                svg.prop("fill", string.concat("#", string(buffer)))
                            ),
                            utils.NULL
                        )
                    );
                } else {
                    string memory color = backgroundColor(t, i);
                    checks = string.concat(
                        checks,
                        svg.el(
                            "use",
                            string.concat(
                                svg.prop("href", "#c"),
                                svg.prop("x", LibString.toString(160 + x * 40)),
                                svg.prop("y", LibString.toString(160 + y * 40)),
                                svg.prop("fill", color)
                            ),
                            utils.NULL
                        )
                    );
                }
                ++i;
            }
        }

        return string.concat(
            '<svg width="1240" height="1240" viewBox="0 0 1240 1240" fill="none" xmlns="http://www.w3.org/2000/svg">',
            "<defs>",
            '<g id="c"><rect x="-20" y="-20" width="40" height="40" stroke="#191919" fill="#111111"/><circle r="4"/><circle cx="6" r="4"/><circle cy="6" r="4"/><circle cx="-6" r="4"/><circle cy="-6" r="4"/><circle cx="4.243" cy="4.243" r="4"/><circle cx="4.243" cy="-4.243" r="4"/><circle cx="-4.243" cy="4.243" r="4"/><circle cx="-4.243" cy="-4.243" r="4"/><path d="m-.6 3.856 4.56-6.844c.566-.846-.75-1.724-1.316-.878L-1.38 2.177-2.75.809c-.718-.722-1.837.396-1.117 1.116l2.17 2.15a.784.784 0 0 0 .879-.001.767.767 0 0 0 .218-.218Z" fill="#111111"/></g>',
            "</defs>",
            svg.rect(
                string.concat(svg.prop("width", "1240"), svg.prop("height", "1240"), svg.prop("fill", "black")),
                utils.NULL
            ),
            svg.rect(
                string.concat(
                    svg.prop("x", "130"),
                    svg.prop("y", "130"),
                    svg.prop("width", "980"),
                    svg.prop("height", "980"),
                    svg.prop("fill", "#111111")
                ),
                utils.NULL
            ),
            checks,
            "</svg>"
        );
    }

    function backgroundColor(uint256 t, uint256 i) private pure returns (string memory) {
        if (t == 1) return "#a59afeff";
        if (t == 2) return "#638596ff";
        if (t == 3) {
            if (i < 24 || i >= 552 || (i % 24 == 0) || (i % 24 == 23)) return "#FFD700ff";
            return "#638596ff";
        }
        if (t == 4) return "#3EB489ff";
        revert("Invalid color");
    }
}