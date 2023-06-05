// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Base64.sol";

contract Horizons is ERC721, Ownable {
    using Strings for uint256;

    string constant TITLE = "Horizon";
    string constant DESCRIPTION =
        unicode"81 Horizons is a collection of 81 on-chain landscapes.\\n\\nEach work consists of a unique combination of two colored rectangles.\\n\\nRafaël Rozendaal, 2021\\n\\nLicense: CC BY-NC-ND 4.0";

    string constant JSON_PROTOCOL_URI = "data:application/json;base64,";
    string constant SVG_PROTOCOL_URI = "data:image/svg+xml;base64,";

    string constant SVG_TOKEN_0 =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 800" shape-rendering="crispEdges"><rect fill="#';
    string constant SVG_TOKEN_1 = '" width="1200" height="800"/><rect fill="#';
    string constant SVG_TOKEN_2 = '" y="576" width="1200" height="224"/></svg>';

    uint8 constant MAX_SUPPLY = 81;

    // 17 colors, RBG format. A hex array would take half of the space of a
    // string, but it would require more code to generate a string from it.
    bytes constant PALETTE =
        "72d0eb00a7a800a545006837b8ffdeffff9bffb43ec4e9fb29abe2bfbfbf0071bc060e9f060e574f4f4f000000ffe3fffea0c9";

    // Every byte represents the color palette of an artwork.
    // Note that the number of colors il 17 (from 0 to 16), so a byte is not
    // enough to fit two colors, but this is true for all artworks < 75.
    // Artworks from 75, to 81 have as secondary color that is encoded to `F`.
    // In `getSVG` there is some extra logic that checks the value of `tokenId`
    // and, if it's the case, hardcodes the color number to 16.
    bytes ARTWORKS =
        hex"0102030405060708097172737475767879a1a2a3a4a5a6a7a8abacadb1b2b3b7b8bcbebdb9c3c8cbcecde3ebecede9d1d2d3d8dbdcded991929394959697989b9c9e9df1f4f5f6f7f8f901040506070809";

    constructor() ERC721("81 Horizons", "81H") {}

    function safeMintAll(
        address to,
        uint8 start,
        uint8 end,
        uint8 step
    ) external onlyOwner {
        require(start > 0, "Horizons: invalid tokenId");
        require(end <= MAX_SUPPLY, "Horizons: supply exceeded");
        for (uint256 tokenId = start; tokenId <= end; tokenId += step) {
            _safeMint(to, tokenId);
        }
    }

    function safeMint(address to, uint8 tokenId) external onlyOwner {
        require(tokenId > 0, "Horizons: invalid tokenId");
        require(tokenId <= MAX_SUPPLY, "Horizons: supply exceeded");
        _safeMint(to, tokenId);
    }

    function getSVG(uint256 tokenId) public view returns (string memory) {
        uint8 artwork = uint8(ARTWORKS[tokenId - 1]);
        uint8 color1;
        uint8 color2 = (artwork & 0x0f) * 6;
        if (tokenId < 75) {
            color1 = (artwork >> 4) * 6;
        } else {
            color1 = 16 * 6;
        }

        return
            Base64.encode(
                abi.encodePacked(
                    SVG_TOKEN_0,
                    PALETTE[color1],
                    PALETTE[color1 + 1],
                    PALETTE[color1 + 2],
                    PALETTE[color1 + 3],
                    PALETTE[color1 + 4],
                    PALETTE[color1 + 5],
                    abi.encodePacked(
                        SVG_TOKEN_1,
                        PALETTE[color2],
                        PALETTE[color2 + 1],
                        PALETTE[color2 + 2],
                        PALETTE[color2 + 3],
                        PALETTE[color2 + 4],
                        PALETTE[color2 + 5],
                        SVG_TOKEN_2
                    )
                )
            );
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        bytes memory image = abi.encodePacked(
            SVG_PROTOCOL_URI,
            getSVG(tokenId)
        );

        bytes memory number = abi.encodePacked(tokenId.toString());

        bytes memory json = abi.encodePacked(
            '{"name":"',
            TITLE,
            " ",
            number,
            '",',
            '"description":"',
            DESCRIPTION,
            '",',
            '"image":"',
            image,
            '"}'
        );
        return string(abi.encodePacked(JSON_PROTOCOL_URI, Base64.encode(json)));
    }
}