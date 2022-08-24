// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

import "./GIFEncoder.sol";

interface ICrypToadzCustomImages {
    function isCustomImage(uint256 tokenId) external view returns (bool);
    function getCustomImage(uint256 tokenId) external view returns (bytes memory buffer);
}