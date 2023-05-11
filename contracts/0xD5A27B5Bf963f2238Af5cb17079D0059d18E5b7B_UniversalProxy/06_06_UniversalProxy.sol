//SPDX-License-Identifier: GPL-3.0
// Creator: Metalist Labs
pragma solidity ^0.8.0;

import "./lib/ProxyOwnable.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract UniversalProxy is Proxy, ProxyOwnable {
    using Address for address;

    bytes32 private constant _IMPLEMENT_ADDRESS_POSITION = keccak256("Gaas.impl.address.84c2ce47");

    bytes32 private constant _OWNER_POSITION = keccak256("Gaas-Proxy.owner.7e2efd65");

    function setImplementAddress(address nft)public onlyProxyOwner {
        require(nft.isContract(), "ADDRESS SHOULD BE CONTRACT");

        bytes32 position = _IMPLEMENT_ADDRESS_POSITION;
        assembly {
            sstore(position, nft)
        }
    }

    function getImplementAddress() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal view virtual override returns (address) {
        bytes32 position = _IMPLEMENT_ADDRESS_POSITION;
        address impl;

        assembly {
            impl := sload(position)
        }

        return impl;
    }

    function _storeProxyOwner(address _owner) internal override {
        bytes32 position = _OWNER_POSITION;

        assembly {
            sstore(position, _owner)
        }
    }

    function _loadProxyOwner() internal view override returns (address) {
        bytes32 position = _OWNER_POSITION;
        address _owner;

        assembly {
            _owner := sload(position)
        }

        return _owner;
    }

}