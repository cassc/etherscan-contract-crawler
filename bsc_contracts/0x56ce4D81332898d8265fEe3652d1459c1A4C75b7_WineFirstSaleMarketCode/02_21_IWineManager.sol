// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IWineManagerFactoryIntegration.sol";
import "./IWineManagerFirstSaleMarketIntegration.sol";
import "./IWineManagerMarketPlaceIntegration.sol";
import "./IWineManagerDeliveryServiceIntegration.sol";
import "./IWineManagerPoolIntegration.sol";
import "./IWineManagerBordeauxCityBondIntegration.sol";

interface IWineManager is
    IWineManagerFactoryIntegration,
    IWineManagerFirstSaleMarketIntegration,
    IWineManagerMarketPlaceIntegration,
    IWineManagerDeliveryServiceIntegration,
    IWineManagerPoolIntegration,
    IWineManagerBordeauxCityBondIntegration
{

}