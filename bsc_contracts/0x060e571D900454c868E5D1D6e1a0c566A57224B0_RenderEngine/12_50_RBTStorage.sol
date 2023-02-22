// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

contract RBTStorage {
    mapping(address => bool) public minters;

    /// @dev gap for potential vairable
    uint256[49] private _gap;
}