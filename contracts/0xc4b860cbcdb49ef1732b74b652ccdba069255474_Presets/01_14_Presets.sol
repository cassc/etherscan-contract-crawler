// SPDX-License-Identifier: UNLICENSE
pragma solidity 0.8.18;

import {Curra} from "./Curra.sol";
import {WhitelistedAddressRule} from "./WhitelistedAddressRule.sol";
import {AuthorizedSenderRule} from "./AuthorizedSenderRule.sol";
import {Forwarder} from "./Forwarder.sol";

contract Presets {
    Curra internal immutable curra;

    constructor(address curraAddress) {
        curra = Curra(curraAddress);
    }

    /// @notice Used to mint new ownerships and deploy whitelisted address rule in one transaction
    /// @param recipient - address to mint ownership to
    /// @param whitelistedAddress - address that will be whitelisted in rule
    function mintWithWhitelistRule(address recipient, address whitelistedAddress)
        public
        returns (uint256 id, address ruleProxy, address forwarder)
    {
        // add salt to avoid repeating rules in case of multiple mints on different chains
        bytes32 nftSalt = keccak256(abi.encode(whitelistedAddress, address(this)));
        id = curra.mint(recipient, nftSalt);

        // precalculate proxy address, so it can be used in forwarder implementation
        address ruleProxyComputed = curra.predictProxyAddress(id);

        // deploy proxy and set implementation
        forwarder = address(new Forwarder{salt: bytes32(id)}(ruleProxyComputed));

        address rule = address(new WhitelistedAddressRule(whitelistedAddress, address(forwarder)));

        ruleProxy = curra.deployProxy(id, rule);
    }

    /// @notice Used to mint new ownerships and deploy authorized sender rule in one transaction
    /// @param recipient - address to mint ownership to
    /// @param authorizedSender - address that will be authorized in rule
    function mintWithAuthorizedSenderRule(address recipient, address authorizedSender)
        public
        returns (uint256 id, address ruleProxy, address forwarder)
    {
        // add salt to avoid repeating rules in case of multiple mints on different chains
        bytes32 nftSalt = keccak256(abi.encode(authorizedSender, address(this)));
        id = curra.mint(recipient, nftSalt);

        // precalculate proxy address, so it can be used in forwarder implementation
        address ruleProxyComputed = curra.predictProxyAddress(id);

        // deploy proxy and set implementation
        forwarder = address(new Forwarder{salt: bytes32(id)}(ruleProxyComputed));

        address rule = address(new AuthorizedSenderRule(authorizedSender, address(forwarder)));

        ruleProxy = curra.deployProxy(id, rule);
    }
}