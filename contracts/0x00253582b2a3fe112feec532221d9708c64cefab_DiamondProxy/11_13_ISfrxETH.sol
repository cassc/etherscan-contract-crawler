// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

/// @title ISfrxETH
/// @notice Interface for the `sfrxETH` contract
interface ISfrxETH {
    function pricePerShare() external view returns (uint256);
}