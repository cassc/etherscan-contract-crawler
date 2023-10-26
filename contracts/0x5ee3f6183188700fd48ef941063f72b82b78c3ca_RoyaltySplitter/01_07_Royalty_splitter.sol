// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract RoyaltySplitter is PaymentSplitter {

    struct revenueShareParams {
        address[] payees;
        uint256[] shares;
    }

    constructor(
        revenueShareParams memory revenueShare
    ) PaymentSplitter(
        revenueShare.payees, revenueShare.shares
    ) {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function withdraw() external callerIsUser {
        this.release(payable(msg.sender));
    }
}