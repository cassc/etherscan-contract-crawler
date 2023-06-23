// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./exchange/Exchange.sol";

/**
 * @title WyvernExchange
 * @author Wyvern Protocol Developers
 * @author Unvest
 * @dev Updated from Wyvern Exchange v3.3
 */
contract WyvernExchange is Exchange {
    string public constant name = "Unvest Protocol";
    string public constant version = "1.0";

    constructor(
        uint256 chainId,
        address[] memory registryAddrs,
        bytes memory customPersonalSignPrefix
    ) {
        DOMAIN_SEPARATOR = hash(
            EIP712Domain({
                name: name,
                version: version,
                chainId: chainId,
                verifyingContract: address(this)
            })
        );
        for (uint256 ind = 0; ind < registryAddrs.length; ind++) {
            registries[registryAddrs[ind]] = true;
        }
        if (customPersonalSignPrefix.length > 0) {
            personalSignPrefix = customPersonalSignPrefix;
        }
    }
}