// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IDiamondReadableController } from "./IDiamondReadableController.sol";
import { DiamondReadableModel } from "./DiamondReadableModel.sol";
import { ProxyFacetedController } from "../../core/proxy/faceted/ProxyFacetedController.sol";

abstract contract DiamondReadableController is
    IDiamondReadableController,
    DiamondReadableModel,
    ProxyFacetedController
{
    function facets_() internal view virtual returns (Facet[] memory) {
        return _facets();
    }

    function facetFunctionSelectors_(address facet)
        internal
        view
        virtual
        returns (bytes4[] memory)
    {
        return _facetFunctionSelectors(facet);
    }

    function facetAddresses_() internal view virtual returns (address[] memory) {
        return _facetAddresses();
    }

    function facetAddress_(bytes4 selector) internal view virtual returns (address) {
        return _implementation(selector);
    }
}