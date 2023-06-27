// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IEnhanceable.sol";
import "../lib/Stats.sol";

interface IHeroURIHandler is IEnhanceable {
    function tokenURI(uint256 tokenId) external view returns (string memory);

    function getStats(uint256 tokenId)
        external
        view
        returns (Stats.HeroStats memory);

    function getSeeder() external view returns (address);

    function enhanceFor(
        uint256 tokenId,
        uint256 burnTokenId,
        address user
    ) external;

    function revealFor(uint256[] calldata tokenIds, address user) external;

    function getGuild() external view returns (address);
}