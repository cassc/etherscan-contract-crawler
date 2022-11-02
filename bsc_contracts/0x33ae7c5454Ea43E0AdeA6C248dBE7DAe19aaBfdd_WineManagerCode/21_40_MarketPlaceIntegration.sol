// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "../interfaces/IWineManagerMarketPlaceIntegration.sol";
import "../interfaces/IWineMarketPlace.sol";
import "../proxy/TransparentUpgradeableProxyInitializable.sol";
import "../proxy/ITransparentUpgradeableProxyInitializable.sol";

abstract contract MarketPlaceIntegration is IWineManagerMarketPlaceIntegration
{
    address public override marketPlace;

    function _initializeMarketPlace(
        address proxyAdmin_,
        address wineMarketPlaceCode_,
        address[] memory allowedCurrencies_,
        uint256 orderFeeInPromille_
    )
        internal
    {
        marketPlace = address(new TransparentUpgradeableProxyInitializable());
        ITransparentUpgradeableProxyInitializable(marketPlace).initializeProxy(wineMarketPlaceCode_, proxyAdmin_, bytes(""));
        IWineMarketPlace(marketPlace).initialize(address(this), allowedCurrencies_, orderFeeInPromille_);
    }

}