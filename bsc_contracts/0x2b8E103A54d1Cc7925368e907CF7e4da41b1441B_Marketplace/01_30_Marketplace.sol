// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import './MarketplaceBase.sol';

contract Marketplace is MarketplaceBase {
    constructor(
        IERC20 ayraToken,
        IERC20 ithdToken,
        address _profit,
        address priceFeed,
        address _owner,
        address _bridgeAdmin
    ) {
        _network = Network.Binance;
        _ayraToken = ayraToken;
        _ithdToken = ithdToken;
        profit = _profit;

        _transferOwnership(_owner);

        _priceFeed = priceFeed;
        
        bridgeAdmin = _bridgeAdmin;
        
        _grantRole(BRIDGE_ADMIN, bridgeAdmin);

        AffiliateStatistics
            storage _affiliateStatisticsAYRA = affiliateStatistics[
                TokenType.AYRA
            ];
        AffiliateStatistics
            storage _affiliateStatisticsITHD = affiliateStatistics[
                TokenType.ITHD
            ];

        _affiliateStatisticsAYRA.maxDistribution = 50_000_000_000_000 ether;
        _affiliateStatisticsITHD.maxDistribution = 10_000_000 ether;

        _affiliateStatisticsAYRA.affiliateRatio = 0.000_000_44 ether;
        _affiliateStatisticsITHD.affiliateRatio = 0.001_25 ether;

        tokenPriceUSD[TokenType.AYRA] = 0.000_000_007 ether;
        tokenPriceUSD[TokenType.ITHD] = 0.01 ether;

        maxSaleAmountForRewardsEther = 250 ether;
    }
}