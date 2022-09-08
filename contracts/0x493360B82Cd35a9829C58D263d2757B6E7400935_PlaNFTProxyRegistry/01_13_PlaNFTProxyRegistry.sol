// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./AuthenticatedProxy.sol";
import "./ProxyRegistry.sol";

contract PlaNFTProxyRegistry is ProxyRegistry {
    string public constant name = "Project PlaNFT Proxy Registry";

    /* Count the initial auth address has been set. */
    uint256 public initialAddressCount = 0;

    constructor() {
        delegateProxyImplementation = address(new AuthenticatedProxy());
    }

    /**
     * Grant authentication to the initial Exchange protocol contract
     *
     * @dev No delay, can only be called once - after that the standard registry process with a delay must be used
     * @param authAddress Address of the contract to grant authentication
     */
    function grantInitialAuthentication(address authAddress) public onlyOwner {
        require(initialAddressCount < 3, "Only 3 initial auth addresses allowed.");
        initialAddressCount++;
        contracts[authAddress] = true;
    }
}