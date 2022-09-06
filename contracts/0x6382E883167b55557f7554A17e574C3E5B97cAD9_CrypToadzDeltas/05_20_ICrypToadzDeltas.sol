// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

import "./GIFFrame.sol";

interface ICrypToadzDeltas {
    function drawDelta(GIFFrame memory frame, uint tokenId, uint8 deltaFile) external view returns (uint32[] memory buffer);
    function getDeltaFileForToken(uint tokenId) external view returns (int8);
}