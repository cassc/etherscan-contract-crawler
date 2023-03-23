// SPDX-License-Identifier: MIT

pragma solidity >=0.8.11;


import "./libraries/Configable.sol";

contract MarketRegistry is Configable {

    struct TradeDetails {
        uint256 marketId;
        uint256 value;
        bytes tradeData;
    }

    struct Market {
        address proxy;
        bool isLib;
        bool isActive;
    }

    Market[] public markets;

    constructor(address[] memory proxies, bool[] memory isLibs) {
        owner = msg.sender;
        for (uint256 i = 0; i < proxies.length; i++) {
            markets.push(Market(proxies[i], isLibs[i], true));
        }
    }

    function addMarket(address proxy, bool isLib) external onlyDev {
        markets.push(Market(proxy, isLib, true));
    }

    function setMarketStatus(uint256 marketId, bool newStatus) external onlyDev {
        Market storage market = markets[marketId];
        market.isActive = newStatus;
    }

    function setMarketProxy(uint256 marketId, address newProxy, bool isLib) external onlyDev {
        Market storage market = markets[marketId];
        market.proxy = newProxy;
        market.isLib = isLib;
    }

    function marketsLength() external view returns (uint) {
        return markets.length;
    }

    function getMarkets() external view returns (Market[] memory) {
        return markets;
    }
}