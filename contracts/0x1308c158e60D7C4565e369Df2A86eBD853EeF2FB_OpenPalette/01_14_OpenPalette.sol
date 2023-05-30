// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract OpenPalette is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Open Palette", "OPL") {}

    function safeMint(address to) private {
        uint256 nextId = _tokenIdCounter.current();

        require(nextId < 9900, "Token limit reached");

        _safeMint(to, nextId);
        _tokenIdCounter.increment();
    }

    function claim() public {
        safeMint(_msgSender());
    }

    function ownerClaim(uint256 tokenId) public onlyOwner {
        require(tokenId >= 9900 && tokenId < 10000, "Token ID invalid");
        _safeMint(owner(), tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /** CUSTOM */

    function generateLine(uint256 color, uint256 y)
        private
        pure
        returns (string memory)
    {
        string memory textColor = getContrastingColor(color);
        string memory backgroundColor = getColorHexCode(color);

        return
            string(
                abi.encodePacked(
                    '<rect y="',
                    toString(y),
                    '%" width="100%" height="20%" fill="',
                    backgroundColor,
                    '" /><text x="38%" y="',
                    toString(y + 12),
                    '%" fill="',
                    textColor,
                    '" class="base">',
                    backgroundColor,
                    "</text>"
                )
            );
    }

    function generateSVG(
        uint256 color1,
        uint256 color2,
        uint256 color3,
        uint256 color4,
        uint256 color5
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { font-family: monospace; font-weight: bold; font-size: 20px; }</style><rect width="100%" height="100%" />',
                    generateLine(color1, 0),
                    generateLine(color2, 20),
                    generateLine(color3, 40),
                    generateLine(color4, 60),
                    generateLine(color5, 80),
                    "</svg>"
                )
            );
    }

    function tokenURI(uint256 tokenId)
        public
        pure
        override
        returns (string memory)
    {
        uint256 color1 = getColor1(tokenId);
        uint256 color2 = getColor2(tokenId);
        uint256 color3 = getColor3(tokenId);
        uint256 color4 = getColor4(tokenId);
        uint256 color5 = getColor5(tokenId);

        string memory codes = string(
            abi.encodePacked(
                getColorHexCode(color1),
                ", ",
                getColorHexCode(color2),
                ", ",
                getColorHexCode(color3),
                ", ",
                getColorHexCode(color4),
                ", and ",
                getColorHexCode(color5)
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Palette #',
                        toString(tokenId),
                        '", "description": "A color palette containing 5 color codes: ',
                        codes,
                        '.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(
                            bytes(
                                generateSVG(
                                    color1,
                                    color2,
                                    color3,
                                    color4,
                                    color5
                                )
                            )
                        ),
                        '"}'
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /** COLOR LIBRARY */

    function generateColor(string memory prefix, uint256 tokenId)
        private
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(prefix, tokenId))) % 4096;
    }

    function getColor1(uint256 tokenId) public pure returns (uint256) {
        return generateColor("1", tokenId);
    }

    function getColor2(uint256 tokenId) public pure returns (uint256) {
        return generateColor("2", tokenId);
    }

    function getColor3(uint256 tokenId) public pure returns (uint256) {
        return generateColor("3", tokenId);
    }

    function getColor4(uint256 tokenId) public pure returns (uint256) {
        return generateColor("4", tokenId);
    }

    function getColor5(uint256 tokenId) public pure returns (uint256) {
        return generateColor("5", tokenId);
    }

    function getColors(uint256 tokenId) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    getColorHexCode(getColor1(tokenId)),
                    " ",
                    getColorHexCode(getColor2(tokenId)),
                    " ",
                    getColorHexCode(getColor3(tokenId)),
                    " ",
                    getColorHexCode(getColor4(tokenId)),
                    " ",
                    getColorHexCode(getColor5(tokenId))
                )
            );
    }

    function getColorComponentRed(uint256 value)
        internal
        pure
        returns (uint16)
    {
        return uint16((value >> 8) & 0xf);
    }

    function getColorComponentGreen(uint256 value)
        internal
        pure
        returns (uint16)
    {
        return uint16((value >> 4) & 0xf);
    }

    function getColorComponentBlue(uint256 value)
        internal
        pure
        returns (uint16)
    {
        return uint16(value & 0xf);
    }

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function getColorHexCode(uint256 value)
        internal
        pure
        returns (string memory)
    {
        uint16 red = getColorComponentRed(value);
        uint16 green = getColorComponentGreen(value);
        uint16 blue = getColorComponentBlue(value);

        bytes memory buffer = new bytes(7);

        buffer[0] = "#";
        buffer[1] = _HEX_SYMBOLS[red];
        buffer[2] = _HEX_SYMBOLS[red];
        buffer[3] = _HEX_SYMBOLS[green];
        buffer[4] = _HEX_SYMBOLS[green];
        buffer[5] = _HEX_SYMBOLS[blue];
        buffer[6] = _HEX_SYMBOLS[blue];

        return string(buffer);
    }

    function getGammaExpandedComponent(uint16 component)
        internal
        pure
        returns (uint256)
    {
        if (component == 1) return 560;
        if (component == 2) return 1599;
        if (component == 3) return 3310;
        if (component == 4) return 5780;
        if (component == 5) return 9084;
        if (component == 6) return 13286;
        if (component == 7) return 18447;
        if (component == 8) return 24620;
        if (component == 9) return 31854;
        if (component == 10) return 40197;
        if (component == 11) return 49693;
        if (component == 12) return 60382;
        if (component == 13) return 72305;
        if (component == 14) return 85499;
        if (component == 15) return 100000;
        return 0;
    }

    function getLuminance(
        uint16 r,
        uint16 g,
        uint16 b
    ) internal pure returns (uint256) {
        uint256 lumR = getGammaExpandedComponent(r) * 2125;
        uint256 lumG = getGammaExpandedComponent(g) * 7154;
        uint256 lumB = getGammaExpandedComponent(b) * 721;

        return (lumR + lumG + lumB);
    }

    function getIsDark(
        uint16 r,
        uint16 g,
        uint16 b
    ) internal pure returns (bool) {
        return getLuminance(r, g, b) < 500000000;
    }

    function getContrastingColor(uint256 color)
        internal
        pure
        returns (string memory)
    {
        return
            getIsDark(
                getColorComponentRed(color),
                getColorComponentGreen(color),
                getColorComponentBlue(color)
            )
                ? "#ffffff"
                : "#000000";
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}