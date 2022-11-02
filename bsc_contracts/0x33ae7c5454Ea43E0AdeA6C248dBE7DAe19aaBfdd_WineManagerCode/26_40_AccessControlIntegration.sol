// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "../vendors/access/AccessControlExtended.sol";

abstract contract AccessControlIntegration is AccessControlExtended {

    function _initializeAccessControlIntegration(address owner_)
        internal
    {
        _initializeAccessControlExtended(owner_);
    }

    bytes32 internal constant  SYSTEM_ROLE = "SYSTEM_ROLE";
    bytes32 internal constant  FACTORY_MANAGER_ROLE = "FACTORY_MANAGER_ROLE";
    bytes32 internal constant  FIRST_SALE_MARKET_MANAGER_ROLE = "FIRST_SALE_MARKET_MANAGER_ROLE";
    bytes32 internal constant  MARKET_PLACE_MANAGER_ROLE = "MARKET_PLACE_MANAGER_ROLE";
    bytes32 internal constant  DELIVERY_SETTINGS_MANAGER_ROLE = "DELIVERY_SETTINGS_MANAGER_ROLE";
    bytes32 internal constant  DELIVERY_SUPPORT_ROLE = "DELIVERY_SUPPORT_ROLE";


    function addAdmin(address _address)
        public
    {
        grantRole(DEFAULT_ADMIN_ROLE, _address);
    }

    function removeAdmin(address _address)
        public
    {
        revokeRole(DEFAULT_ADMIN_ROLE, _address);
    }

    function addSystem(address _address)
        public
    {
        grantRole(SYSTEM_ROLE, _address);
    }

    function removeSystem(address _address)
        public
    {
        revokeRole(SYSTEM_ROLE, _address);
    }

    function addFactoryManager(address _address)
        public
    {
        grantRole(FACTORY_MANAGER_ROLE, _address);
    }

    function removeFactoryManager(address _address)
        public
    {
        revokeRole(FACTORY_MANAGER_ROLE, _address);
    }

    function addFirstSaleMarketManager(address _address)
        public
    {
        grantRole(FIRST_SALE_MARKET_MANAGER_ROLE, _address);
    }

    function removeFirstSaleMarketManager(address _address)
        public
    {
        revokeRole(FIRST_SALE_MARKET_MANAGER_ROLE, _address);
    }

    function addMarketPlaceManager(address _address)
        public
    {
        grantRole(MARKET_PLACE_MANAGER_ROLE, _address);
    }

    function removeMarketPlaceManager(address _address)
        public
    {
        revokeRole(MARKET_PLACE_MANAGER_ROLE, _address);
    }

    function addDeliverySettingsManager(address _address)
        public
    {
        grantRole(DELIVERY_SETTINGS_MANAGER_ROLE, _address);
    }

    function removeDeliverySettingsManager(address _address)
        public
    {
        revokeRole(DELIVERY_SETTINGS_MANAGER_ROLE, _address);
    }

    function addDeliverySupport(address _address)
        public
    {
        grantRole(DELIVERY_SUPPORT_ROLE, _address);
    }

    function removeDeliverySupport(address _address)
        public
    {
        revokeRole(DELIVERY_SUPPORT_ROLE, _address);
    }

}