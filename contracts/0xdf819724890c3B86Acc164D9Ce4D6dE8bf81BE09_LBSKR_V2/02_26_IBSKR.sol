/*
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.18;

/**
 * @notice Interface of BSKR.
 */
interface IBSKR {
    function balanceOf(address wallet) external view returns (uint256);

    function stakeTransfer(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);
}