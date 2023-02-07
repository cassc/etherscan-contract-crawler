// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IRenderer.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ChecksDefaultRenderer is IPaintingRenderer {
    mapping(uint256 => string) PALETTE;

    constructor() {
        PALETTE[0] = "#F5F5F5";
        PALETTE[1] = "#1595D9";
        PALETTE[2] = "#2045C6";
        PALETTE[3] = "#20972F";
        PALETTE[4] = "#BE2D23";
        PALETTE[5] = "#F9B70F";
    }

    function getColors(uint8[80] memory drawing)
        internal
        pure
        returns (uint8[80] memory)
    {
        uint8[80] memory colors;

        for (uint256 i = 0; i < drawing.length; i++) {
            colors[i] = uint8(drawing[i] % 6);
        }

        return colors;
    }

    function drawCheck(uint8 index, uint8 colorIndex)
        internal
        view
        returns (bytes memory)
    {
        uint32 x = uint32(index % 8) * 106;
        uint32 y = uint32(index / 8) * 106;

        string memory color = PALETTE[colorIndex];

        return
            abi.encodePacked(
                '<g transform="translate(',
                Strings.toString(x),
                ",",
                Strings.toString(y),
                ')">',
                '<path d="M659.204 526.661c0-4.301-2.382-8.031-5.848-9.801.419-1.184.648-2.464.648-3.812 0-6.017-4.656-10.885-10.395-10.885a9.774 9.774 0 0 0-3.637.681c-1.683-3.64-5.244-6.131-9.355-6.131-4.111 0-7.667 2.496-9.357 6.126a9.804 9.804 0 0 0-3.638-.681c-5.744 0-10.395 4.873-10.395 10.89 0 1.345.226 2.625.646 3.812-3.463 1.77-5.846 5.494-5.846 9.801 0 4.071 2.129 7.618 5.288 9.491-.055.463-.088.926-.088 1.4 0 6.016 4.651 10.89 10.395 10.89 1.28 0 2.505-.234 3.635-.681 1.688 3.632 5.244 6.126 9.357 6.126 4.117 0 7.673-2.494 9.358-6.126a9.91 9.91 0 0 0 3.637.675c5.745 0 10.395-4.873 10.395-10.89 0-.474-.033-.936-.09-1.397 3.153-1.87 5.29-5.417 5.29-9.485v-.003Zm-18.012-9.077-11.8 17.697a2.039 2.039 0 0 1-1.702.909c-.389 0-.784-.109-1.132-.343l-.313-.256-6.575-6.575a2.04 2.04 0 1 1 2.886-2.886l4.819 4.811 10.413-15.627a2.043 2.043 0 0 1 2.832-.564 2.04 2.04 0 0 1 .572 2.831v.003Z" fill="',
                color,
                '"/></g>'
            );
    }

    function render(uint256 tokenId, uint8[80] memory drawing)
        external
        view
        returns (string memory)
    {
        uint8[80] memory colors = getColors(drawing);

        bytes memory buffer = bytes(
            '<svg width="2000" height="2000" viewBox="0 0 2000 2000" fill="none" xmlns="http://www.w3.org/2000/svg"><rect width="2000" height="2000" fill="black"/><g transform="scale(1.4)" transform-origin="50% 50%"><rect x="551.108" y="447.852" width="897.783" height="1104.3" fill="#151515"/>'
        );

        for (uint8 i = 0; i < 80; i++) {
            buffer = abi.encodePacked(buffer, drawCheck(i, colors[i]));
        }

        buffer = abi.encodePacked(buffer, "</g></svg>");

        string memory paintingStr = Base64.encode(buffer);

        return
            string(
                abi.encodePacked(
                    'data:application/json;utf8,{"name":"Painted Checks #',
                    Strings.toString(tokenId),
                    '","description": "notable through creativity. checks.studio.","image": "data:image/svg+xml;base64,',
                    paintingStr,
                    '"}'
                )
            );
    }
}