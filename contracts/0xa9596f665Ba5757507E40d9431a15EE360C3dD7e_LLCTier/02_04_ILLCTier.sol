// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface ILLCTier {
    function LEGENDARY_RARITY() external returns (uint256);

    function SUPER_RARE_RARITY() external returns (uint256);

    function RARE_RARITY() external returns (uint256);

    function LLCRarities(uint256) external returns (uint256);
}