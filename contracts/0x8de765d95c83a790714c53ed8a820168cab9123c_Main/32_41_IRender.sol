// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.19;

struct RenderInfo {
    uint72 encoded;
    bool revealed;
    uint256[] traitCounts;
    uint256 tokenId;
    uint256 slot1;
    uint256 slot2;
    uint256 slot3;
}

interface IRender {
    function render(
        RenderInfo calldata r
    ) external view returns (bytes memory bgr);
}