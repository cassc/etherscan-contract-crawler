// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./exchange/Exchange.sol";
import "./registry/ProxyRegistry.sol";
import "./modules/PoolsTransferProxy.sol";
import "./royalties/RoyaltyFeeRegistry.sol";

contract PoolsExchange is Exchange {
    string public constant name = "Pools Exchange";

    /**
     * @dev Initialize a WyvernExchange instance
     * @param registryAddress Address of the registry instance which this Exchange instance will use
     */
    constructor(
        ProxyRegistry registryAddress,
        PoolsTransferProxy tokenTransferProxyAddress,
        RoyaltyFeeRegistry royaltyFeeRegistryAddress
    ) {
        royaltyFeeRegistry = royaltyFeeRegistryAddress;
        registry = registryAddress;
        tokenTransferProxy = tokenTransferProxyAddress;
    }
}