// SPDX-License-Identifier: UNLICENSE
pragma solidity 0.8.18;

import {Curra} from "./Curra.sol";
import {WhitelistedAddressRule} from "./WhitelistedAddressRule.sol";
import {Forwarder} from "./Forwarder.sol";

contract Presets {
    Curra internal immutable curra;

    constructor(address curraAddress) {
        curra = Curra(curraAddress);
    }

    /// @notice Used to mint new ownerships and deploy rule in one transaction
    /// @dev If rule is not provided, then WhitelistedAddressRule will be used with msg.sender as a whitelisted address
    /// @param recipient - address to mint ownership to
    /// @param rule - rule to use for ownership, if not provided, then WhitelistedAddressRule will be used with msg.sender as a whitelisted address
    function mintWithRule(address recipient, address rule)
        public
        returns (uint256 id, address ruleProxy, address forwarder)
    {
        // mint to self temporarily to be able to deploy everything
        id = curra.mint(recipient, bytes32(bytes20(address(this))));

        // precalculate proxy address, so it can be used in forwarder implementation
        address ruleProxyComputed = curra.predictProxyAddress(id);

        // deploy proxy and set implementation
        forwarder = address(new Forwarder{salt: bytes32(id)}(ruleProxyComputed));

        if (rule == address(0)) {
            rule = address(new WhitelistedAddressRule(recipient, address(forwarder)));
        }

        ruleProxy = curra.deployProxy(id, rule);
    }
}