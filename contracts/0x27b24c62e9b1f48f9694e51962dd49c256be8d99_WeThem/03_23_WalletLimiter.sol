// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract WalletLimiter is Ownable {
    uint public maxWalletLimit = 1;

    function getMaxWalletLimit() public view returns(uint) {
        return maxWalletLimit;
    }

    function setMaxWalletLimit(uint WalletLimit) public onlyOwner {
        maxWalletLimit = WalletLimit;
    }
}