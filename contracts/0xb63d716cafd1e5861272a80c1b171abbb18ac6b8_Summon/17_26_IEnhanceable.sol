// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEnhanceable {
    function enhancementCost(uint256 tokenId)
        external
        view
        returns (uint256, bool);

    function enhance(uint256 tokenId, uint256 burnTokenId) external;

    function enhanceFor(
        uint256 tokenId,
        uint256 burnTokenId,
        address user
    ) external;

    function revealFor(uint256[] calldata tokenIds, address user) external;
}