// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title ERC20Storage
 * @author MirrorXYZ
 */
contract ERC20Storage {
    /// @notice EIP-20 token name for this token
    string public name;

    /// @notice EIP-20 token symbol for this token
    string public symbol;

    /// @notice EIP-20 total number of tokens in circulation
    uint256 public totalSupply;

    /// @notice Initialize total supply to zero.
    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
        totalSupply = 0;
    }
}