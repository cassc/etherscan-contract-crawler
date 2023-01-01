// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./ITieredSalesInternal.sol";

interface ITieredSales is ITieredSalesInternal {
    function onTierAllowlist(
        uint256 tierId,
        address minter,
        uint256 maxAllowance,
        bytes32[] calldata proof
    ) external view returns (bool);

    function eligibleForTier(
        uint256 tierId,
        address minter,
        uint256 maxAllowance,
        bytes32[] calldata proof
    ) external view returns (uint256);

    function mintByTier(
        uint256 tierId,
        uint256 count,
        uint256 maxAllowance,
        bytes32[] calldata proof
    ) external payable;

    function remainingForTier(uint256 tierId) external view returns (uint256);

    function walletMintedByTier(uint256 tierId, address wallet) external view returns (uint256);

    function tierMints(uint256 tierId) external view returns (uint256);

    function totalReserved() external view returns (uint256);

    function reservedMints() external view returns (uint256);

    function tiers(uint256 tierId) external view returns (Tier memory);
}