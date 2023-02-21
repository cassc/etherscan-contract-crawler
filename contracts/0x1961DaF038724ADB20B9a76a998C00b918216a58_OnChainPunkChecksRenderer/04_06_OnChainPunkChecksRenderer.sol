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
        bytes memory svgContents = bytes(renderSvg(punkId, t));
        string memory name = string.concat("Punk Checks #", LibString.toString(punkId));
        bytes memory metadata = abi.encodePacked(
            '{"name": "',
            name,
            '","description": "',
            DESCRIPTION,
            '","image": "data:image/svg+xml;base64,',
            Base64.encode(svgContents),
            '",',
            '"animation_url": ',
            '"data:text/html;base64,',
            Base64.encode(generateHTML(punkId, svgContents)),
            '",',
            '"attributes": [',
            '{"trait_type": "Origin","value": "',
            t == 1 ? "CryptoPunks V1" : (t == 2 ? "CryptoPunks V2" : t == 3 ? "CryptoPunks OG" : "CryptoPunks Wannabe"),
            '"}]}'
        );
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(metadata)));
    }

    function generateHTML(uint256 punkId, bytes memory svgContents) public pure returns (bytes memory) {
        return abi.encodePacked(
            "<!DOCTYPE html>",
            '<html lang="en">',
            "<head>",
            "<title>Punk Checks #",
            LibString.toString(punkId),
            "</title>",
            '<meta charset="UTF-8">',
            '<meta http-equiv="X-UA-Compatible" content="IE=edge">',
            '<meta name="viewport" content="width=device-width, initial-scale=1.0">',
            "<style>",
            "html,",
            "body {margin:0;background:#EFEFEF;overflow:hidden;}",
            "svg {max-width:100vw;max-height:100vh;}",
            "</style>",
            "</head>",
            "<body>",
            svgContents,
            "</body>",
            "</html>"
        );
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
                                svg.prop("x", LibString.toString(142 + x * 40)),
                                svg.prop("y", LibString.toString(142 + y * 40)),
                                svg.prop("fill", string.concat("#", string(buffer)))
                            ),
                            utils.NULL
                        )
                    );
                } else {
                    string memory color = backgroundColor(t, x, y);
                    checks = string.concat(
                        checks,
                        svg.el(
                            "use",
                            string.concat(
                                svg.prop("href", "#c"),
                                svg.prop("x", LibString.toString(142 + x * 40)),
                                svg.prop("y", LibString.toString(142 + y * 40)),
                                svg.prop("class", color)
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
            "<style>.v1{fill:#a59afeff} .v2{fill:#638596ff} .v3{fill:#638596ff} .v3a{fill:#638596ff;animation:col 40s ease-out 0s infinite normal both} .v4{fill:#3EB489ff} @keyframes col { 0% {fill:#638596ff} 10%,20% {fill:#a59afeff} 75%,100% {fill:#638596ff} } .d0{} .d1{animation-delay:0.5s} .d2{animation-delay:1s} .d3{animation-delay:1.5s} .d4{animation-delay:2s} .d5{animation-delay:2.5s} .d6{animation-delay:3s} .d7{animation-delay:3.5s} .d8{animation-delay:4s} .d9{animation-delay:4.5s} .d10{animation-delay:5s} .d11{animation-delay:5.5s} .d12{animation-delay:6s} .d13{animation-delay:6.5s} .d14{animation-delay:7s} .d15{animation-delay:7.5s} .d16{animation-delay:8s} .d17{animation-delay:8.5s} .d18{animation-delay:9s} .d19{animation-delay:9.5s} .d20{animation-delay:10s} .d21{animation-delay:10.5s} .d22{animation-delay:11s} .d23{animation-delay:11.5s} .d24{animation-delay:12s} .d25{animation-delay:12.5s} .d26{animation-delay:13s} .d27{animation-delay:13.5s} .d28{animation-delay:14s} .d29{animation-delay:14.5s} .d30{animation-delay:15s} .d31{animation-delay:15.5s} .d32{animation-delay:16s} .d33{animation-delay:16.5s} .d34{animation-delay:17s} .d35{animation-delay:17.5s} .d36{animation-delay:18s} .d37{animation-delay:18.5s} .d38{animation-delay:19s} .d39{animation-delay:19.5s} .d40{animation-delay:20s} .d41{animation-delay:20.5s} .d42{animation-delay:21s} .d43{animation-delay:21.5s} .d44{animation-delay:22s} .d45{animation-delay:22.5s} .d46{animation-delay:23s} .d47{animation-delay:23.5s}</style>",
            "<defs>",
            '<g id="c"><rect x="-2" y="-2" width="40" height="40" stroke="#191919" fill="transparent"/><path fill-rule="evenodd" d="M21.36 9.886A3.933 3.933 0 0 0 18 8c-1.423 0-2.67.755-3.36 1.887a3.935 3.935 0 0 0-4.753 4.753A3.933 3.933 0 0 0 8 18c0 1.423.755 2.669 1.886 3.36a3.935 3.935 0 0 0 4.753 4.753 3.933 3.933 0 0 0 4.863 1.59 3.953 3.953 0 0 0 1.858-1.589 3.935 3.935 0 0 0 4.753-4.754A3.933 3.933 0 0 0 28 18a3.933 3.933 0 0 0-1.887-3.36 3.934 3.934 0 0 0-1.042-3.711 3.934 3.934 0 0 0-3.71-1.043Zm-3.958 11.713 4.562-6.844c.566-.846-.751-1.724-1.316-.878l-4.026 6.043-1.371-1.368c-.717-.722-1.836.396-1.116 1.116l2.17 2.15a.788.788 0 0 0 1.097-.22Z"></path></g>',
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

    function backgroundColor(uint256 t, uint256 x, uint256 y) private pure returns (string memory) {
        if (t == 1) return "v1";
        if (t == 2) return "v2";
        if (t == 3) {
            return string.concat("v3a d", LibString.toString(x + y));
        }
        if (t == 4) return "v4";
        revert("Invalid color");
    }
}