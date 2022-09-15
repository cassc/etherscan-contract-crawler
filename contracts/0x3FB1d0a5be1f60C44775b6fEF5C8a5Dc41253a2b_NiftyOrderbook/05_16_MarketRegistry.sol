pragma solidity ^0.8.4;

import "./lib/Ownable.sol";

contract MarketRegistry is Ownable {
    struct TradeDetails {
        uint256 marketId;
        uint256 value;
        bytes tradeData;
    }

    struct Market {
        address proxy;
        uint256 assetContractSlice;
        uint256 receiverAddressSlice;
        bool isActive;
    }

    Market[] public markets;

    function addMarket(address proxy, uint256 assetContractSlice, uint256 receiverAddressSlice) external onlyOwner {
        markets.push(Market(proxy, assetContractSlice, receiverAddressSlice, true));
    }

    function setMarketStatus(uint256 marketId, bool newStatus)
        external
        onlyOwner
    {
        Market storage market = markets[marketId];
        market.isActive = newStatus;
    }

    function setMarketProxy(
        uint256 marketId,
        address newProxy,
        uint256 assetContractSlice,
        uint256 receiverAddressSlice
    ) external onlyOwner {
        Market storage market = markets[marketId];
        market.proxy = newProxy;
        market.assetContractSlice = assetContractSlice;
        market.receiverAddressSlice = receiverAddressSlice;
    }
}