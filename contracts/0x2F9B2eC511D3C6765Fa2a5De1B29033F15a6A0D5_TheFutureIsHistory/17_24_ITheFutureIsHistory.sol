// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface ITheFutureIsHistory {
    event SaleCreated(
        uint256 indexed stageId,
        uint256 maxAmount,
        uint256 maxPerWallet,
        uint256 maxPerMint,
        uint256 price,
        uint256[] discountQuantities,
        uint256[] discountPrices,
        bool presale,
        bytes32 merkleRoot
    );
}