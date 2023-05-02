// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IDexoStorage {
    // Enums
    enum LimitOrder { TP, SL, LIQ, OPEN }

    // Structs
    struct Trader{
        uint leverageUnlocked;
        address referral;
        uint referralRewardsTotal;  // 1e18
    }
    struct Trade{
        address trader;
        uint pairIndex;
        uint index;
        uint positionSizeDai;       // 1e18
        uint openPrice;             // PRECISION
        bool buy;
        uint leverage;
        uint tp;                    // PRECISION
        uint sl;                    // PRECISION
        uint liq;
    }
    struct TradeInfo{
        address borrowToken;
        uint borrowAmount;
        address positionToken;
        uint positionAmount;
        uint openTime;
        uint tpLastUpdated;
        uint slLastUpdated;
        uint liq;
    }

    struct OpenLimitOrder{
        address trader;
        uint pairIndex;
        uint index;
        uint positionSize;          // 1e18 (DAI or GFARM2)
        bool buy;
        uint leverage;
        uint tp;                    // PRECISION (%)
        uint sl;                    // PRECISION (%)
        uint minPrice;              // PRECISION
        uint maxPrice;              // PRECISION
        uint block;
        uint openTime;
        uint tokenId;               // index in supportedTokens
    }

    function openTrades(address, uint, uint) external view returns(Trade memory);
    function openTradesInfo(address, uint, uint) external view returns(TradeInfo memory);
    function openTradesCount(address, uint) external view returns(uint);

    function openLimitOrdersCount(address, uint) external view returns(uint);
    function maxTradesPerPair() external view returns(uint);

    function storeTrade(Trade memory _trade, TradeInfo memory _tradeInfo) external ;
    function unregisterTrade(address trader, uint pairIndex, uint index) external;
    function storeOpenLimitOrder(OpenLimitOrder memory o) external;
    function updateOpenLimitOrder(OpenLimitOrder calldata _o) external;
    function unregisterOpenLimitOrder(address _trader, uint _pairIndex, uint _index) external;
    function firstEmptyTradeIndex(address trader, uint pairIndex) external view returns(uint index);
    function firstEmptyOpenLimitIndex(address trader, uint pairIndex) external view returns(uint index);
    function hasOpenLimitOrder(address trader, uint pairIndex, uint index) external view returns(bool);
    function setMaxTradesPerPair(uint _maxTradesPerPair) external;
    function updateSl(address _trader, uint _pairIndex, uint _index, uint _newSl) external;
    function updateTp(address _trader, uint _pairIndex, uint _index, uint _newTp) external;
    function getOpenLimitOrder(address _trader, uint _pairIndex,uint _index) external view returns(OpenLimitOrder memory);
    function getOpenLimitOrders() external view returns(OpenLimitOrder[] memory);

}