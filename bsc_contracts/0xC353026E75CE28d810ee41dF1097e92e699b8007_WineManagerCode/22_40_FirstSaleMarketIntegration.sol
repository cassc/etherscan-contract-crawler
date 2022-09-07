// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "../interfaces/IWineManagerFirstSaleMarketIntegration.sol";
import "../interfaces/IWineFirstSaleMarket.sol";
import "../proxy/TransparentUpgradeableProxyInitializable.sol";
import "../proxy/ITransparentUpgradeableProxyInitializable.sol";

abstract contract FirstSaleMarketIntegration is IWineManagerFirstSaleMarketIntegration
{
    address public override firstSaleMarket;

    function _initializeFirstSaleMarket(
        address proxyAdmin_,
        address wineFirstSaleMarketCode_,
        address firstSaleCurrency_
    )
        internal
    {
        firstSaleMarket = address(new TransparentUpgradeableProxyInitializable());
        ITransparentUpgradeableProxyInitializable(firstSaleMarket).initializeProxy(wineFirstSaleMarketCode_, proxyAdmin_, bytes(""));
        IWineFirstSaleMarket(firstSaleMarket).initialize(address(this), firstSaleCurrency_);
    }

}