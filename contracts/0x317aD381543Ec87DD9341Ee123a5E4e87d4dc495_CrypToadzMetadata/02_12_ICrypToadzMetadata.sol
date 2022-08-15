// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

import "./GIFEncoder.sol";

interface ICrypToadzMetadata {
    function isTall(uint256 tokenId) external view returns (bool);
    function getMetadata(uint256 tokenId) external view returns (uint8[] memory metadata);
}