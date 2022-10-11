// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./proxy/ProxyRegistry.sol";
import "./proxy/AuthenticatedProxy.sol";

contract MetaspacecyProxyRegistry is ProxyRegistry {
    string public constant name = "Metaspacecy Proxy Registry";

    bool public initialAddressSet = false;

    constructor() {
        delegateProxyImplementation = address(new AuthenticatedProxy());
    }

    /**
     * Grant authentication to the initial Exchange protocol contract
     * @dev No delay, can only be called once - after that the standard registry process with a delay must be used
     * @param authAddress Address of the contract to grant authentication
     */
    function grantInitialAuthentication(address authAddress) public onlyOwner {
        require(!initialAddressSet, "MPR: initialized");
        initialAddressSet = true;
        contracts[authAddress] = true;
    }
}