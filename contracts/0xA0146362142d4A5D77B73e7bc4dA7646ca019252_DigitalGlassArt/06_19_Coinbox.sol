// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract Coinbox is PaymentSplitter, Ownable {
    uint256 private payeeCount;

    constructor(
        address[] memory _payees, 
        uint256[] memory _shares
    ) payable PaymentSplitter(_payees, _shares) {
        payeeCount = _payees.length;
    }

    function withdraw() external {
        release(payable(msg.sender));
    }

    function withdrawAll() external onlyOwner {
        require(address(this).balance > 0, "No balance to withdraw");

        for (uint256 i = 0; i < payeeCount; i++) {
            release(payable(payee(i)));
        }
    }
}