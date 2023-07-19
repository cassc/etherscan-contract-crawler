// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

/// @author 3n16m4.eth (c) 2023
/// @notice Make a wish 11:11 (https://11h11.io)

interface IPriceOracle {
    function lastPrice() external view returns (uint256);
}