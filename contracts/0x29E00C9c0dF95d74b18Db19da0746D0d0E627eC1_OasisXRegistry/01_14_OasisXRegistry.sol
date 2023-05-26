//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./registry/ProxyRegistry.sol";
import "./registry/AuthenticatedProxy.sol";

/**
 * @title OasisXRegistry
 * @notice Registry contract
 * @author OasisX Protocol | cryptoware.eth
 */
contract OasisXRegistry is ProxyRegistry {
    string public constant name = "OasisX Protocol Proxy Registry";

    /* Whether the initial auth address has been set. */
    bool public initialAddressSet = false;

    event ExchangeAuthenticated
    (
        address indexed Exchange
    );

    constructor() {
        AuthenticatedProxy impl = new AuthenticatedProxy();
        impl.initialize(address(this), this);
        impl.setRevoke(true);
        delegateProxyImplementation = address(impl);
    }

    /**
     * Grant authentication to the initial Exchange protocol contract
     *
     * @dev No delay, can only be called once - after that the standard registry process with a delay must be used
     * @param authAddress Address of the contract to grant authentication
     */
    function grantInitialExchangeAuthentication(address authAddress)
        external
        onlyOwner
    {
        require(
            !initialAddressSet,
            "OasisXRegistry: initial address already set"
        );
        initialAddressSet = true;
        contracts[authAddress] = true;
        emit ExchangeAuthenticated(authAddress);
    }
}