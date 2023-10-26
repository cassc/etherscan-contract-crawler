// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

/// @title ICbETH
/// @notice Interface for the `cbETH` contract
interface ICbETH {
    function exchangeRate() external view returns (uint256);
}