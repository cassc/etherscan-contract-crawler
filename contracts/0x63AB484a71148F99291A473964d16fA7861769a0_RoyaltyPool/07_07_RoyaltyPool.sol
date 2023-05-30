// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {PaymentSplitter} from "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RoyaltyPool is PaymentSplitter {
    constructor(
        address[] memory payees,
        uint256[] memory shares_
    ) PaymentSplitter(payees, shares_) {}

    function releaseEther(address payable _address) external {
        release(_address);
    }

    function releaseERC20(IERC20 token) external {
        release(token, msg.sender);
    }
}