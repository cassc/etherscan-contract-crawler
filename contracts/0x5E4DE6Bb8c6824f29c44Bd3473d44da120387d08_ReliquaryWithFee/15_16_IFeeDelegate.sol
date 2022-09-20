/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

/**
 * @title Fee provider
 * @author Theori, Inc.
 * @notice Acceptor of fees for functions requiring payment
 */
interface IFeeDelegate {
    /**
     * @notice Accept any required fee from the sender
     * @param sender the originator of the call that may be paying
     * @param data opaque data to help determine costs
     * @dev reverts if a fee is required and not provided
     */
    function checkFee(address sender, bytes calldata data) external payable;
}