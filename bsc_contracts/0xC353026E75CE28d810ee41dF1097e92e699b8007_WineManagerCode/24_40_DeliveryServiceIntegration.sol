// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "../interfaces/IWineDeliveryService.sol";
import "../interfaces/IWineManagerDeliveryServiceIntegration.sol";
import "../proxy/TransparentUpgradeableProxyInitializable.sol";
import "../proxy/ITransparentUpgradeableProxyInitializable.sol";

abstract contract DeliveryServiceIntegration is IWineManagerDeliveryServiceIntegration
{
    address public override deliveryService;

    function _initializeDeliveryService(
        address proxyAdmin_,
        address wineDeliveryServiceCode_
    )
        internal
    {
        deliveryService = address(new TransparentUpgradeableProxyInitializable());
        ITransparentUpgradeableProxyInitializable(deliveryService).initializeProxy(wineDeliveryServiceCode_, proxyAdmin_, bytes(""));
        IWineDeliveryService(deliveryService).initialize(address(this));
    }

}