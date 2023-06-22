// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "fount-contracts/utils/GenericPaymentSplitter.sol";
import "./interfaces/IDriversPayments.sol";

/**
 * @author Fount Gallery
 * @title  Drivers Payments
 * @notice Payment splitter for recieving sale proceeds
 */
contract DriversPayments is IDriversPayments, GenericPaymentSplitter {
    constructor(address[] memory payees_, uint256[] memory shares_)
        GenericPaymentSplitter(payees_, shares_)
    {}

    function releaseAllETH() external {
        _releaseAllETH();
    }

    function releaseAllToken(address tokenAddress) external {
        _releaseAllToken(tokenAddress);
    }
}