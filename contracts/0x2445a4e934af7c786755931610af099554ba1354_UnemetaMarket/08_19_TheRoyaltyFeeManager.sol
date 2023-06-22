// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface TheRoyaltyManager {
    function calculateRoyaltyFeeAndGetRecipient(
        address collection,
        uint256 tokenId,
        uint256 amount
    ) external view returns (address, uint256);
}