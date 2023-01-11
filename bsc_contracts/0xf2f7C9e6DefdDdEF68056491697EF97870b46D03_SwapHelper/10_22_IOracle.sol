// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

interface IOracle {
    /// @notice Gives price of token in terms of another token
    function getPrice(address token, address inTermsOf) external view returns (uint);
}