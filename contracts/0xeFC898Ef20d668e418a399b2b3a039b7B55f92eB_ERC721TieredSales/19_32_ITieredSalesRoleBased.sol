// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface ITieredSalesRoleBased {
    function mintByTierByRole(
        address minter,
        uint256 tierId,
        uint256 count,
        uint256 maxAllowance,
        bytes32[] calldata proof
    ) external payable;
}