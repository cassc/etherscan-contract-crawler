// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title ILendingPool
/// @author Protectorate
/// @notice Interface for BendDao lending pool.
interface ILendingPool {
    function deposit(address reserve, uint256 amount, address onBehalfOf, uint16 referralCode)
        external;

    function withdraw(address reserve, uint256 amount, address to) external returns (uint256);
}