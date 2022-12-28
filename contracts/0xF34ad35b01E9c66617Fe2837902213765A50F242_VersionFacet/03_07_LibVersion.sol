// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

library LibVersion {
    /**
     * @notice Retrieves the function selector's facet address from a list of Facet structs
     * @param _selector function selector to look up
     * @param _facets Array of Facet structs that could contain the function selector
     */
    function getSelectorFacetAddress(
        bytes4 _selector,
        IDiamondLoupe.Facet[] memory _facets
    ) internal pure returns (address) {
        for (uint256 i = 0; i < _facets.length; ) {
            for (uint256 j = 0; j < _facets[i].functionSelectors.length; ) {
                if (_facets[i].functionSelectors[j] == _selector) {
                    return _facets[i].facetAddress;
                }
                unchecked {
                    j++;
                }
            }
            unchecked {
                i++;
            }
        }
        return address(0);
    }

    /**
     * @notice Retrieves the function selector's facet address from a list of FacetCut structs
     * @param _selector function selector to look up
     * @param _facets Array of FacetCut structs that could contain the function selector
     */
    function getSelectorFacetCutAddress(
        bytes4 _selector,
        IDiamondCut.FacetCut[] memory _facets
    ) internal pure returns (address) {
        for (uint256 i = 0; i < _facets.length; ) {
            for (uint256 j = 0; j < _facets[i].functionSelectors.length; ) {
                if (_facets[i].functionSelectors[j] == _selector) {
                    return _facets[i].facetAddress;
                }
                unchecked {
                    j++;
                }
            }
            unchecked {
                i++;
            }
        }
        return address(0);
    }

    /**
     * @notice Compares two EIP-2535 Diamonds and checks if have same facets
     * @param _currentFacets Current Diamond facets (array of Facut structs retrieved from the `facets()` function in the `DiamondLouperFacet`)
     * @param _modelDiamondCut Model Diamond facets (as array of FacetCut structs)
     */
    function diamondEquals(
        IDiamondLoupe.Facet[] memory _currentFacets,
        IDiamondCut.FacetCut[] memory _modelDiamondCut
    ) internal pure returns (bool) {
        // 1) Check Current Diamond against the Model Diamond
        for (uint256 i = 0; i < _currentFacets.length; ) {
            for (
                uint256 j = 0;
                j < _currentFacets[i].functionSelectors.length;

            ) {
                // Check if the selector exists in the Model Diamond
                bytes4 selector = _currentFacets[i].functionSelectors[j];
                address foundAddress = getSelectorFacetCutAddress(
                    selector,
                    _modelDiamondCut
                );
                unchecked {
                    j++;
                }
                if (foundAddress == _currentFacets[i].facetAddress) continue;
                // selector was removed or its facet address was changed -> Not equal
                return false;
            }
            unchecked {
                i++;
            }
        }

        // 2) Check Model Diamond against the Current Diamond
        for (uint256 i = 0; i < _modelDiamondCut.length; ) {
            for (
                uint256 j = 0;
                j < _modelDiamondCut[i].functionSelectors.length;

            ) {
                // Check if the selector exists in the Current Diamond
                bytes4 selector = _modelDiamondCut[i].functionSelectors[j];
                address foundAddress = getSelectorFacetAddress(
                    selector,
                    _currentFacets
                );
                unchecked {
                    j++;
                }
                if (foundAddress == _modelDiamondCut[i].facetAddress) continue;
                // selector was removed or its facet address was changed -> Not equal
                return false;
            }
            unchecked {
                i++;
            }
        }

        // 3) If we went here it's because diamonds are equal
        return true;
    }
}