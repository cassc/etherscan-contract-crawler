// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

/// @title IRETH
/// @notice Interface for the `rETH` contract
interface IRETH {
    function getExchangeRate() external view returns (uint256);
}