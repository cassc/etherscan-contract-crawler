// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IDiamondReadable } from "./IDiamondReadable.sol";
import { proxyFacetedStorage, ProxyFacetedStorage } from "../../core/proxy/faceted/ProxyFacetedStorage.sol";

abstract contract DiamondReadableModel {
    function _facets()
        internal
        view
        virtual
        returns (IDiamondReadable.Facet[] memory facets)
    {
        ProxyFacetedStorage storage ps = proxyFacetedStorage();
        facets = new IDiamondReadable.Facet[](ps.implementations.length);
        uint256[] memory current = new uint256[](facets.length);

        unchecked {
            for (uint256 i; i < facets.length; i++) {
                address facet = ps.implementations[i];
                uint256 selectorCount = ps.implementationInfo[facet].selectorCount;
                facets[i].facetAddress = facet;
                facets[i].functionSelectors = new bytes4[](selectorCount);
            }

            for (uint256 i; i < ps.selectors.length; i++) {
                bytes4 selector = ps.selectors[i];
                address facet = ps.selectorInfo[selector].implementation;
                uint256 position = ps.implementationInfo[facet].position;
                facets[position].functionSelectors[current[position]++] = selector;
            }
        }
    }

    function _facetFunctionSelectors(address facet)
        internal
        view
        virtual
        returns (bytes4[] memory selectors)
    {
        ProxyFacetedStorage storage ps = proxyFacetedStorage();
        selectors = new bytes4[](ps.implementationInfo[facet].selectorCount);
        uint256 index;

        unchecked {
            for (uint256 i; index < selectors.length; i++) {
                bytes4 selector = ps.selectors[i];

                if (ps.selectorInfo[selector].implementation == facet) {
                    selectors[index++] = selector;
                }
            }
        }
    }

    function _facetAddresses() internal view virtual returns (address[] memory) {
        return proxyFacetedStorage().implementations;
    }
}