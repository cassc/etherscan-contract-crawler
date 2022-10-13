// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "./proxies/FungibleOriginationPoolProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * Manages deployment of fungible origination pool proxies
 * Deploys fungible proxies pointing to fungible origination pool implementation
 */
contract PoolDeployer is Ownable {
    address public fungibleOriginationPoolImplementation;

    constructor(address _fungibleOriginationPoolImplementation) {
        fungibleOriginationPoolImplementation = _fungibleOriginationPoolImplementation;
        emit FungibleOriginationPoolImplementationSet(
            _fungibleOriginationPoolImplementation
        );
    }

    function deployFungibleOriginationPool(address _proxyAdmin)
        external
        returns (address pool)
    {
        FungibleOriginationPoolProxy proxy = new FungibleOriginationPoolProxy(
            fungibleOriginationPoolImplementation,
            _proxyAdmin,
            address(this)
        );
        return address(proxy);
    }

    function setFungibleOriginationPoolImplementation(
        address _fungibleOriginationPoolImplementation
    ) external onlyOwner {
        fungibleOriginationPoolImplementation = _fungibleOriginationPoolImplementation;
        emit FungibleOriginationPoolImplementationSet(
            _fungibleOriginationPoolImplementation
        );
    }

    // Events

    event FungibleOriginationPoolImplementationSet(
        address indexed fungibleOriginationPoolImplementation
    );
}