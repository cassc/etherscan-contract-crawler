// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract TXLimiter is Ownable {
    uint public maxTXLimit = 1;

    function getMaxTXLimit() public view returns(uint) {
        return maxTXLimit;
    }

    function setMaxTXLimit(uint TXLimit) public onlyOwner {
        maxTXLimit = TXLimit;
    }
}