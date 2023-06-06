//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract OpenSea {
    address private _proxyRegistry;

    function proxyRegistry() public view returns (address) {
        return _proxyRegistry;
    }

    function isOwnersOpenSeaProxy(address owner, address operator)
        public
        view
        returns (bool)
    {
        address proxyRegistry_ = _proxyRegistry;

        if (proxyRegistry_ != address(0)) {
            if (block.chainid == 1 || block.chainid == 4) {
                return
                    address(ProxyRegistry(proxyRegistry_).proxies(owner)) ==
                    operator;
            } else if (block.chainid == 137 || block.chainid == 80001) {
                return proxyRegistry_ == operator;
            }
        }

        return false;
    }

    function _setOpenSeaRegistry(address proxyRegistryAddress) internal {
        _proxyRegistry = proxyRegistryAddress;
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}