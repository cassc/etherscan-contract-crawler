// SPDX-License-Identifier: AGPL-3.0
// ©2023 Ponderware Ltd

pragma solidity ^0.8.17;

import "../Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library PixelSVG {
    function wrap (bytes memory content) internal pure returns (string memory) {
        return string(abi.encodePacked("<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMidYMid meet' viewBox='0 0 600 600' width='600' height='600' shape-rendering='crispEdges' style='image-rendering:pixelated'>",
                                       content,
                                       "</svg>"));
    }

    function encodeBase64URI (string memory svg) internal pure returns (string memory) {
        return string(abi.encodePacked("data:image/svg+xml;base64,",Base64.encode(bytes(svg))));
    }

    function rect (uint x, uint y, uint width, uint height, uint8 r, uint8 g, uint8 b, uint8 a) internal pure returns (bytes memory) {
        return abi.encodePacked(abi.encodePacked("<rect x='",
                                                 Strings.toString(x),
                                                 "' y='",
                                                 Strings.toString(y),
                                                 "' width='",
                                                 Strings.toString(width),
                                                 "' height='",
                                                 Strings.toString(height),
                                                 "' fill='rgba("),
                                abi.encodePacked(Strings.toString(r),",",
                                                 Strings.toString(g),",",
                                                 Strings.toString(b),",",
                                                 Strings.toString(a),")'/>"));
    }

    function img (int x, int y, uint width, uint height, string memory src) internal pure returns (bytes memory) {
        string memory negX;
        string memory negY;

        if (x < 0) {
            x = -x;
            negX = "-";
        }
        if (y < 0) {
            y = -y;
            negY = "-";
        }

        string memory widthString = Strings.toString(width);
        string memory heightString = Strings.toString(height);
        return abi.encodePacked(abi.encodePacked("<foreignObject x='",
                                                 negX, Strings.toString(uint(x)),
                                                 "' y='",
                                                 negY, Strings.toString(uint(y)),
                                                 "' width='",
                                                 widthString,
                                                 "' height='"),
                                heightString,
                                "'><img xmlns='http://www.w3.org/1999/xhtml' style='image-rendering:pixelated' width='",
                                widthString,
                                "' height='",
                                heightString,
                                "' src='",
                                src,
                                "'></img></foreignObject>");
    }

    function img (int x, int y, uint width, uint height, string memory src, string memory className) internal pure returns (bytes memory) {
      string memory negX;
        string memory negY;

        if (x < 0) {
            x = -x;
            negX = "-";
        }
        if (y < 0) {
            y = -y;
            negY = "-";
        }

        string memory widthString = Strings.toString(width);
        string memory heightString = Strings.toString(height);
        return abi.encodePacked(abi.encodePacked("<foreignObject x='",
                                                 negX, Strings.toString(uint(x)),
                                                 "' y='",
                                                 negY, Strings.toString(uint(y)),
                                                 "' width='",
                                                 widthString,
                                                 "' height='"),
                                heightString,
                                "'><img xmlns='http://www.w3.org/1999/xhtml' style='image-rendering:pixelated' class='",
                                className,
                                "' width='",
                                widthString,
                                "' height='",
                                heightString,
                                "' src='",
                                src,
                                "'></img></foreignObject>");
    }

}