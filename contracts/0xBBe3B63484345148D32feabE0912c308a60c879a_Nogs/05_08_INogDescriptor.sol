// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.15;

import "../library/Structs.sol";

interface INogDescriptor {
    function constructTokenURI(Structs.Nog memory nog, uint256 tokenId) external view returns (string memory);
    function getColorPalette(address minterAddress, uint256 tokenId) external view returns (string[7] memory);
    function getPseudorandomness(uint tokenId, uint num) external view returns (uint256 pseudorandomness);
    function setDescription(string memory description) external returns (string memory);
    function getStylesCount() external view returns (uint16 stylesCount);
    function getBackgroundIndex(uint16 backgroundOdds) external pure returns (uint16 backgroundIndex);
}