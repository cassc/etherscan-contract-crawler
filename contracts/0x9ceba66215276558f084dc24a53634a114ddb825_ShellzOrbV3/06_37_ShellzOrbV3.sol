// SPDX-License-Identifier: MIT
// Built for Shellz Orb by megsdevs
pragma solidity 0.8.17;

import {
    ShellzOrbSeadropUpgradeable
} from "./ShellzOrbSeadropUpgradeable.sol";

/**
 * @title  ShellzOrbV3
 * @author megsdevs
 * @notice ShellzOrbV3 is the Shellz Orb NFT V3 contract that contains methods
 *         to interact with SeaDrop.
 */
contract ShellzOrbV3 is 
    ShellzOrbSeadropUpgradeable
{
    
    /**
     *  @notice disable initialization of the implementation contract so connot bypass the proxy.
    */  
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     *  @notice reinitializer allows initialisation on upgrade, in this case for version 2.
    */ 
    function initializeV3(
        address[] memory allowedSeaDrop
    ) public reinitializer(3) {
        __ERC721SeaDrop_init(name(), symbol(), allowedSeaDrop);
    }

}