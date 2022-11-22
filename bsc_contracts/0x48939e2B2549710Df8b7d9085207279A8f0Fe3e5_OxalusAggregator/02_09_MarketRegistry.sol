// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract MarketRegistry is Ownable {
    struct Market {
        address proxy;
        bool isLib;
        bool isActive;
    }

    Market[] public markets;

    constructor(address[] memory proxies, bool[] memory isLibs) {
        for (uint256 i = 0; i < proxies.length; i++) {
            markets.push(Market(proxies[i], isLibs[i], true));
        }
    }

    function getMarket(uint256 index)
        public
        view
        returns (
            address,
            bool,
            bool
        )
    {
        return (markets[index].proxy, markets[index].isLib, markets[index].isActive);
    }

    function addMarket(address proxy, bool isLib) external onlyOwner {
        markets.push(Market(proxy, isLib, true));
    }

    function setMarketStatus(uint256 marketId, bool newStatus) external onlyOwner {
        Market storage market = markets[marketId];
        market.isActive = newStatus;
    }

    function setMarketProxy(
        uint256 marketId,
        address newProxy,
        bool isLib
    ) external onlyOwner {
        Market storage market = markets[marketId];
        market.proxy = newProxy;
        market.isLib = isLib;
    }
}