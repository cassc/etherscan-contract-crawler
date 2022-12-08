// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./openzeppelin/Ownable2Step.sol";

/// @notice Stores proxies to markeplaces
abstract contract MarketRegistry is Ownable2Step {
    struct Market {
        address proxy;
        bool isLib;
        bool isActive;
    }

    Market[] public markets;

    constructor(Market[] memory _markets) {
        for (uint256 i; i < _markets.length; i++) {
            markets.push(_markets[i]);
        }
    }

    function addMarket(Market calldata market) external onlyOwner {
        markets.push(market);
    }

    function setMarketStatus(uint256 marketId, bool newStatus)
        external
        onlyOwner
    {
        Market storage market = markets[marketId];
        market.isActive = newStatus;
    }
}