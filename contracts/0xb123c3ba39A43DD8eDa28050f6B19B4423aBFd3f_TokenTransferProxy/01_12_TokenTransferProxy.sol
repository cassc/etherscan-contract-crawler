// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "../registry/ProxyRegistry.sol";
import "../libraries/TransferHelper.sol";
import "./ERC20.sol";

contract TokenTransferProxy {
    /* Authentication registry. */
    ProxyRegistry public registry;

    constructor(ProxyRegistry _registry)
    {
        require(address(_registry) != address(0), "INVALID REGISTRY");
        registry = _registry;
    }

    /**
     * Call ERC20 `transferFrom`
     *
     * @dev Authenticated contract only
     * @param token ERC20 token address
     * @param from From address
     * @param to To address
     * @param amount Transfer amount
     */
    function transferFrom(address token, address from, address to, uint amount)
        public
    {
        require(registry.contracts(msg.sender));
        TransferHelper.safeTransferFrom(token, from, to, amount);
    }

}