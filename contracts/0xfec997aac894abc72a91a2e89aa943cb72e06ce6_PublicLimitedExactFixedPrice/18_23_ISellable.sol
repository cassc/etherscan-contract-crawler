// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.0 <0.9.0;

/**
 * @notice Basic interface for a contract providing sellable content.
 */
interface ISellable {
    /**
     * @notice Handles the sale of sellable content.
     * @dev This is usually only callable by Sellers.
     */
    function handleSale(address to, uint64 num, bytes calldata data) external payable;
}