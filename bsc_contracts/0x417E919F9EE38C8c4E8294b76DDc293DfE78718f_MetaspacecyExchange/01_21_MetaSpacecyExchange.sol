// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./exchange/Exchange.sol";
import "./proxy/ProxyRegistry.sol";
import "./proxy/TokenTransferProxy.sol";

contract MetaspacecyExchange is Exchange {
    string public constant name = "Metaspacecy Exchange";
    string public constant version = "1.0";

    constructor(
        ProxyRegistry registryAddress,
        TokenTransferProxy tokenTransferProxyAddress,
        IERC20 tokenAddress,
        address protocolFeeAddress,
        uint32 chainId
    ) {
        registry = registryAddress;
        tokenTransferProxy = tokenTransferProxyAddress;
        exchangeToken = tokenAddress;
        protocolFeeRecipient = protocolFeeAddress;
        DOMAIN_SEPARATOR = hash(EIP712Domain({
            name: name,
            version: version,
            chainId: chainId,
            verifyingContract: address(this)
        }));
    }
}