// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @notice Data estructure used to prove membership to a criteria tree.
/// @dev Account, token & amount are used to encode the leaf.
struct CriteriaResolver {
    // Address that is part of the criteria tree
    address account;
    // Amount of ERC20 token
    uint256 balance;
    // Proof of membership to the tree
    bytes32[] proof;
}