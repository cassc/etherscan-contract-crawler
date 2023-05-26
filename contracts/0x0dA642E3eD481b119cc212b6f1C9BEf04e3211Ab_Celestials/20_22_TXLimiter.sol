// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract TXLimiter is Ownable {
    uint256 public maxTXLimit = 5;

    function setMaxTXLimit(uint256 txLimit) public onlyOwner {
        require(txLimit > 0, "InvalidTXLimit");
        maxTXLimit = txLimit;
    }

    function checkTXLimit(uint256 quantity) internal view {
        require(quantity <= maxTXLimit, "ExeededTXLimit");
    }
}