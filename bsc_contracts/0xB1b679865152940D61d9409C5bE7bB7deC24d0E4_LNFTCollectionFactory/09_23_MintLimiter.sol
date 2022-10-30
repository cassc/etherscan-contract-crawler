// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract MintLimiter is Ownable {
    uint256 private maxMintAmountPerTx = 10;

    function getMaxMintLimit() public view returns (uint256) {
        return maxMintAmountPerTx;
    }

    function setMaxMintLimit(uint256 _limit) external onlyOwner {
        maxMintAmountPerTx = _limit;
    }
}