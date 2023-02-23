// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

interface OpenLevInterface {
    struct Market {
        // Market info
        address pool0; // Lending Pool 0
        address pool1; // Lending Pool 1
        address token0; // Lending Token 0
        address token1; // Lending Token 1
        uint16 marginLimit; // Margin ratio limit for specific trading pair. Two decimal in percentage, ex. 15.32% => 1532
        uint16 feesRate; // feesRate 30=>0.3%
        uint16 priceDiffientRatio;
        address priceUpdater;
        uint256 pool0Insurance; // Insurance balance for token 0
        uint256 pool1Insurance; // Insurance balance for token 1
    }

    function markets(uint16 marketId) external view returns (Market memory market);

    function taxes(uint16 marketId, address token, uint index) external view returns (uint24);

    function getMarketSupportDexs(uint16 marketId) external view returns (uint32[] memory);

    function updatePrice(uint16 marketId, bytes memory dexData) external;
}