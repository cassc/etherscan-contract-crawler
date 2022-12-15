// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./ControllableCrossChainUpgradeable.sol";

abstract contract UUPSCrosschainUpgradeable is
    UUPSUpgradeable,
    ControllableCrossChainUpgradeable
{
    // INITIALIZERS
    function __UUPSCrosschainUpgradeable_init() internal onlyInitializing {
        __UUPSCrosschainUpgradeable_init_unchained();
    }

    function __UUPSCrosschainUpgradeable_init_unchained()
        internal
        onlyInitializing
    {
        _setDeployer(msg.sender);
    }

    // INTERNAL
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyCrossChainOwner
    {}
}