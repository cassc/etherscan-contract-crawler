// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library MaxWalletCalculator {
    function calculateMaxWallet(uint256 totalSupply, uint256 hatchTime) public view returns (uint256) {
        if(hatchTime == 0) {
            return totalSupply;
        }

        uint256 FACTOR_MAX = 10000;

        uint256 chameleonAge = block.timestamp - hatchTime;

        uint256 base = totalSupply * 30 / FACTOR_MAX; // 0.3%
        uint256 incrasePerMinute = totalSupply * 10 / FACTOR_MAX; // 0.1%

        uint256 extra = incrasePerMinute * chameleonAge / (1 minutes); // up 0.1% per minute

        return base + extra;
    }
}