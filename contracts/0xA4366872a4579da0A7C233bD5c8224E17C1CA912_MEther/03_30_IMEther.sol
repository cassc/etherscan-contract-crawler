// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "./IMToken.sol";

/**
 * @title Minterest MEther Contract
 * @author Minterest
 */
interface IMEther is IMToken {
    /**
     * @notice Lends native ETH in exchange for mWETH token
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     */
    function lendNative() external payable;

    /**
     * @notice Redeems mWETH in exchange for native ETH
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of mWETH tokens to redeem
     */
    function redeemNative(uint256 redeemTokens) external;

    /**
     * @notice Redeems mWETH in exchange for native ETH
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of native ETH to receive from redeeming mTokens
     */
    function redeemUnderlyingNative(uint256 redeemAmount) external;

    /**
     * @notice Borrows native ETH from the protocol to their own address
     * @param borrowAmount The amount of the native ETH to borrow
     */
    function borrowNative(uint256 borrowAmount) external;

    /**
     * @notice Repays their own borrow
     * @dev repayAmount corresponds to the amount of sent native ETH
     */
    function repayBorrowNative() external payable;

    /**
     * @notice Repays a borrow belonging to borrower
     * @param borrower the account with the debt being payed off
     * @dev repayAmount corresponds to the amount of sent native ETH
     */
    function repayBorrowBehalfNative(address borrower) external payable;
}