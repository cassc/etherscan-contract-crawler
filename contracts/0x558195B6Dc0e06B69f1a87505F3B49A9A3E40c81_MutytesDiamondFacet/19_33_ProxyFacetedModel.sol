// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { proxyFacetedStorage, ProxyFacetedStorage, SelectorInfo, ImplementationInfo } from "./ProxyFacetedStorage.sol";

abstract contract ProxyFacetedModel {
    function _implementation(bytes4 selector) internal view virtual returns (address) {
        return proxyFacetedStorage().selectorInfo[selector].implementation;
    }

    function _addFunction(
        bytes4 selector,
        address implementation,
        bool isUpgradable
    ) internal virtual {
        ProxyFacetedStorage storage ps = proxyFacetedStorage();
        ps.selectorInfo[selector] = SelectorInfo(
            isUpgradable,
            uint16(ps.selectors.length),
            implementation
        );
        ps.selectors.push(selector);
    }

    function _replaceFunction(bytes4 selector, address implementation) internal virtual {
        proxyFacetedStorage().selectorInfo[selector].implementation = implementation;
    }

    function _removeFunction(bytes4 selector) internal virtual {
        ProxyFacetedStorage storage ps = proxyFacetedStorage();
        uint16 position = ps.selectorInfo[selector].position;
        uint256 lastPosition = ps.selectors.length - 1;

        if (position != lastPosition) {
            bytes4 lastSelector = ps.selectors[lastPosition];
            ps.selectors[position] = lastSelector;
            ps.selectorInfo[lastSelector].position = position;
        }

        ps.selectors.pop();
        delete ps.selectorInfo[selector];
    }

    function _afterAddFunction(address implementation) internal virtual {
        ProxyFacetedStorage storage ps = proxyFacetedStorage();
        ImplementationInfo memory info = ps.implementationInfo[implementation];

        if (++info.selectorCount == 1) {
            info.position = uint16(ps.implementations.length);
            ps.implementations.push(implementation);
        }

        ps.implementationInfo[implementation] = info;
    }

    function _afterRemoveFunction(address implementation) internal virtual {
        ProxyFacetedStorage storage ps = proxyFacetedStorage();
        ImplementationInfo memory info = ps.implementationInfo[implementation];

        if (--info.selectorCount == 0) {
            uint16 position = info.position;
            uint256 lastPosition = ps.implementations.length - 1;

            if (position != lastPosition) {
                address lastImplementation = ps.implementations[lastPosition];
                ps.implementations[position] = lastImplementation;
                ps.implementationInfo[lastImplementation].position = position;
            }

            ps.implementations.pop();
            delete ps.implementationInfo[implementation];
        } else {
            ps.implementationInfo[implementation] = info;
        }
    }

    function _setUpgradableFunction(bytes4 selector, bool isUpgradable) internal virtual {
        proxyFacetedStorage().selectorInfo[selector].isUpgradable = isUpgradable;
    }

    function _isUpgradable(bytes4 selector) internal view virtual returns (bool) {
        return proxyFacetedStorage().selectorInfo[selector].isUpgradable;
    }
}