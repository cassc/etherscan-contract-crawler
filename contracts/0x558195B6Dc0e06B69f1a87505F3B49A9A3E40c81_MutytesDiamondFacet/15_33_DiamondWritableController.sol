// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IDiamondWritableController } from "./IDiamondWritableController.sol";
import { ProxyFacetedController } from "../../core/proxy/faceted/ProxyFacetedController.sol";
import { OwnableController } from "../../core/access/ownable/OwnableController.sol";
import { AddressUtils } from "../../core/utils/AddressUtils.sol";
import { IntegerUtils } from "../../core/utils/IntegerUtils.sol";

abstract contract DiamondWritableController is
    IDiamondWritableController,
    ProxyFacetedController,
    OwnableController
{
    using AddressUtils for address;
    using IntegerUtils for uint256;

    function diamondCut_(
        FacetCut[] memory facetCuts,
        address init,
        bytes memory data
    ) internal virtual {
        unchecked {
            for (uint256 i; i < facetCuts.length; i++) {
                FacetCut memory facetCut = facetCuts[i];

                if (facetCut.action == FacetCutAction.Add) {
                    addFunctions_(
                        facetCut.functionSelectors,
                        facetCut.facetAddress,
                        false
                    );
                } else if (facetCut.action == FacetCutAction.Replace) {
                    replaceFunctions_(facetCut.functionSelectors, facetCut.facetAddress);
                } else if (facetCut.action == FacetCutAction.Remove) {
                    removeFunctions_(facetCut.functionSelectors);
                } else {
                    revert UnexpectedFacetCutAction(facetCut.action);
                }
            }
        }

        emit DiamondCut(facetCuts, init, data);
        initializeDiamondCut_(init, data);
    }

    function initializeDiamondCut_(address init, bytes memory data) internal virtual {
        if (init == address(0)) {
            data.length.enforceIsZero();
        } else {
            data.length.enforceIsNotZero();

            if (init != address(this)) {
                init.enforceIsContract();
            }

            _Proxy(init, data);
        }
    }
}