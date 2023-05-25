// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.0 <0.9.0;

/**
 * @notice Interface to execute purchases in `Seller`s.
 * @dev This executes the final purchase. This can be anything from minting ERC721 tokens to transfering funds, etc.
 */
abstract contract PurchaseExecuter {
    function _executePurchase(address to, uint64 num, uint256 cost, bytes memory data) internal virtual;
}