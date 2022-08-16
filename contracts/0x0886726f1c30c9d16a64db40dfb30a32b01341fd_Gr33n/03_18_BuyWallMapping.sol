// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./Counters.sol";

contract BuyWallMapping is Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private buyWallHoldersCount;

    mapping(address => bool) private buyWallHoldersMap;

    function includeToGreenWallMap(address account) external onlyOwner {
        if (buyWallHoldersMap[account] == false) {
            buyWallHoldersMap[account] = true;
            buyWallHoldersCount.increment();
            }
    }

    function excludeToGreenWallMap(address account) external onlyOwner {
        if (buyWallHoldersMap[account] == true) {
            buyWallHoldersMap[account] = false;
            buyWallHoldersCount.decrement();
            }
    }

    function setIncludeToGreenWallMap(address _address, bool _isIncludeToGreenWallMap) external onlyOwner {
        buyWallHoldersMap[_address] = _isIncludeToGreenWallMap;
    }

    function isPartOfGreenWall(address _address) external view returns (bool) {
        return buyWallHoldersMap[_address];
    }

    function getNumberOfGreenWallHolders() external view returns (uint256) {
        return buyWallHoldersCount.current();
    }

    function resetBuyWallHoldersCount() external onlyOwner {
        buyWallHoldersCount.reset();
    }

}