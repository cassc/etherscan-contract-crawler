// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

import "./IBuilder.sol";

interface IRandom { 
    // function randomTokenURI(uint64 seed) external view returns (string memory);
    function randomImageURI(uint64 seed, IBuilder builder, IPixelRenderer renderer, IAnimationEncoder encoder) external view returns (string memory imageUri, uint8[] memory meta);
}