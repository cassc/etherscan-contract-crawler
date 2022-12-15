// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./UUPSCrosschainUpgradeable.sol";

abstract contract UUPSCrosschainPausableUpgradeable is
    UUPSCrosschainUpgradeable,
    PausableUpgradeable
{
    // INITIALIZERS
    function __UUPSCrosschainPausableUpgradeable_init()
        internal
        onlyInitializing
    {
        __UUPSCrosschainUpgradeable_init_unchained();
        __Pausable_init_unchained();
        __UUPSCrosschainPausableUpgradeable_init_unchained();
    }

    function __UUPSCrosschainPausableUpgradeable_init_unchained()
        internal
        onlyInitializing
    {}

    // EXTERNAL
    function pause() external onlyCrossChainOwner {
        _pause();
    }

    function unpause() external onlyCrossChainOwner {
        _unpause();
    }
}