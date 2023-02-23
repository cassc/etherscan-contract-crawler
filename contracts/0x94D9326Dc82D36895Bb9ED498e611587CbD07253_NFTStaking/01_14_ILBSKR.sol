/*
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.18;

/**
 * @notice Interface of LBSKR.
 */
interface ILBSKR {
    function balanceOf(address wallet) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
}