// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {USBT} from "usbt/USBT.sol";
import {ColorLib} from "./lib/ColorLib.sol";
import {UniversalOpepenRenderer} from "./UniversalOpepenRenderer.sol";

contract UnversalOpepen is USBT {
    error InvalidSlot();

    event MetadataUpdate(uint256 tokenId);

    /**
     * @dev `_tokenData` contains packed color informations for slots 0 - 9:
     *          [0..0]      `claimed`
     *          [1..1]      `burned`
     *          [2..25]     `slot 0 color`
     *          [26..49]    `slot 1 color`
     *          [50..73]    `slot 2 color`
     *          [74..97]    `slot 3 color`
     *          [98..121]   `slot 4 color`
     *          [122..145]  `slot 5 color`
     *          [146..169]  `slot 6 color`
     *          [170..193]  `slot 7 color`
     *          [194..217]  `slot 8 color`
     *          [218..241]  `slot 9 color`
     *          [242..249]  `background [0-7]`
     *
     *      '_tokenData2' contains packed color informations for slots 10 - 19
     *          [0..23]     `slot 10 color`
     *          [24..47]    `slot 11 color`
     *          [48..71]    `slot 12 color`
     *          [72..95]    `slot 13 color`
     *          [96..119]   `slot 14 color`
     *          [120..143]  `slot 15 color`
     *          [144..167]  `slot 16 color`
     *          [168..191]  `slot 17 color`
     *          [192..215]  `slot 18 color`
     *          [216..239]  `slot 19 color`
     *          [240..256]  `background [8-23]`
     */
    mapping(uint256 tokenId => uint256 packedData) internal _tokenData2;

    UniversalOpepenRenderer public immutable renderer;

    constructor(address renderer_) USBT("Universal Opepen", "UOpepen") {
        renderer = UniversalOpepenRenderer(renderer_);
    }

    function claim(bytes3[21] calldata colors_) external {
        uint256 tokenId = uint256(uint160(msg.sender));

        _claim();

        (_tokenData[tokenId], _tokenData2[tokenId]) = _packColors(_tokenData[tokenId], _tokenData2[tokenId], colors_);
    }

    function edit(bytes3[21] calldata colors_) external {
        uint256 tokenId = uint256(uint160(msg.sender));
        uint256 tokenData = _tokenData[tokenId];

        if (tokenData & 1 == 0) revert InvalidTokenId();
        if (tokenData & 2 == 2) revert InvalidTokenId();

        (_tokenData[tokenId], _tokenData2[tokenId]) = _packColors(tokenData, _tokenData2[tokenId], colors_);

        emit MetadataUpdate(tokenId);
    }

    function burn() external {
        _burn();
    }

    function claimed(address account) external view returns (bool) {
        uint256 tokenId = uint256(uint160(account));
        uint256 tokenData = _tokenData[tokenId];
        
        return tokenData & 1 == 1;
    }

    function burned(address account) external view returns (bool) {
        uint256 tokenId = uint256(uint160(account));
        uint256 tokenData = _tokenData[tokenId];

        return tokenData & 2 == 2;
    }

    function color(uint256 tokenId, uint256 slot) external view validTokenId(tokenId) returns (bytes3) {
        if (slot > 20) revert InvalidSlot();

        return _unpackColor(slot, _tokenData[tokenId], _tokenData2[tokenId]);
    }

    function colors(uint256 tokenId) public view validTokenId(tokenId) returns (bytes3[] memory) {
        uint256 tokenData = _tokenData[tokenId];
        uint256 tokenData2 = _tokenData2[tokenId];
        bytes3[] memory _colors = new bytes3[](21);

        unchecked {
            for (uint256 i; i < 21; ++i) {
                _colors[i] = _unpackColor(i, tokenData, tokenData2);
            }
        }
        return _colors;
    }

    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        return renderer.render(tokenId, colors(tokenId));
    }

    function _packColors(uint256 tokenData, uint256 tokenData2, bytes3[21] calldata colors_)
        internal
        pure
        returns (uint256, uint256)
    {
        unchecked {
            for (uint256 i; i < 10; ++i) {
                tokenData = ColorLib.packColor(tokenData, i, uint24(colors_[i]));
            }
            for (uint256 i = 10; i < 20; ++i) {
                tokenData2 = ColorLib.packColor(tokenData2, i, uint24(colors_[i]));
            }
            return ColorLib.packBackground(tokenData, tokenData2, uint24(colors_[20]));
        }
    }

    function _unpackColor(uint256 slot, uint256 tokenData, uint256 tokenData2) internal pure returns (bytes3) {
        if (slot < 10) return bytes3(ColorLib.unpackColor(tokenData, slot));
        if (slot < 20) return bytes3(ColorLib.unpackColor(tokenData2, slot));
        else return bytes3(ColorLib.unpackBackground(tokenData, tokenData2));
    }
}