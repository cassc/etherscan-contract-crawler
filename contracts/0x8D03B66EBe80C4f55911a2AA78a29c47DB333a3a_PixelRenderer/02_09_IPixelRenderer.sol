// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

import "./DrawFrame.sol";

interface IPixelRenderer {
    function drawFrameWithOffsets(DrawFrame memory f) external pure returns (uint32[] memory buffer, uint);
    function getColorTable(bytes memory buffer, uint position) external pure returns(uint32[] memory colors, uint);
}