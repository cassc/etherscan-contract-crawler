//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import {PaymentSplitter} from "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract PSplitter is PaymentSplitter {
    constructor(
        address[] memory payees,
        uint256[] memory shares
    ) PaymentSplitter(
        payees,
        shares
    ) payable {}
}