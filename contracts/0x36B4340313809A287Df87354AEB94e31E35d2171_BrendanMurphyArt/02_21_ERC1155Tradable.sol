// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;


import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract OwnableDelegateProxy { }

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * Opensea tradable
 */
abstract contract ERC1155Tradable is ERC1155{
    address proxyRegistryAddress;

    constructor(address _proxyRegistryAddress) {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function isApprovedForAll(
        address _owner,
        address _operator
    ) public view  override virtual returns (bool isOperator) {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
        return true;
        }

        return ERC1155.isApprovedForAll(_owner, _operator);
    }
}