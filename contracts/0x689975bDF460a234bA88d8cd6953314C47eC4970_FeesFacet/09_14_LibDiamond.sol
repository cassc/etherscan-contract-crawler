// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {IDiamondCutFacet} from "../interfaces/IDiamondCutFacet.sol";

/// @title meTokens Protocol diamond library
/// @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/// @notice Diamond library to enable library storage of meTokens protocol.
/// @dev EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
library LibDiamond {
    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
        bytes4[] functionSelectors;
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    event DiamondCut(
        IDiamondCutFacet.FacetCut[] diamondCut,
        address init,
        bytes data
    );

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCutFacet.FacetCut[] memory cut,
        address init,
        bytes memory data
    ) internal {
        for (uint256 facetIndex; facetIndex < cut.length; facetIndex++) {
            IDiamondCutFacet.FacetCutAction action = cut[facetIndex].action;
            if (action == IDiamondCutFacet.FacetCutAction.Add) {
                addFunctions(
                    cut[facetIndex].facetAddress,
                    cut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCutFacet.FacetCutAction.Replace) {
                replaceFunctions(
                    cut[facetIndex].facetAddress,
                    cut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCutFacet.FacetCutAction.Remove) {
                removeFunctions(
                    cut[facetIndex].facetAddress,
                    cut[facetIndex].functionSelectors
                );
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(cut, init, data);
        initializeDiamondCut(init, data);
    }

    function addFunctions(
        address facetAddress,
        bytes4[] memory functionSelectors
    ) internal {
        require(
            functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress == address(0),
                "LibDiamondCut: Can't add function that already exists"
            );
            addFunction(ds, selector, selectorPosition, facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(
        address facetAddress,
        bytes4[] memory functionSelectors
    ) internal {
        require(
            functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress != facetAddress,
                "LibDiamondCut: Can't replace function with same function"
            );
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(
        address facetAddress,
        bytes4[] memory functionSelectors
    ) internal {
        require(
            functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(
            facetAddress == address(0),
            "LibDiamondCut: Remove facet address must be address(0)"
        );
        for (
            uint256 selectorIndex;
            selectorIndex < functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address facetAddress)
        internal
    {
        enforceHasContractCode(
            facetAddress,
            "LibDiamondCut: New facet has no code"
        );
        ds.facetFunctionSelectors[facetAddress].facetAddressPosition = ds
            .facetAddresses
            .length;
        ds.facetAddresses.push(facetAddress);
    }

    function addFunction(
        DiamondStorage storage ds,
        bytes4 selector,
        uint96 selectorPosition,
        address facetAddress
    ) internal {
        ds
            .selectorToFacetAndPosition[selector]
            .functionSelectorPosition = selectorPosition;
        ds.facetFunctionSelectors[facetAddress].functionSelectors.push(
            selector
        );
        ds.selectorToFacetAndPosition[selector].facetAddress = facetAddress;
    }

    function removeFunction(
        DiamondStorage storage ds,
        address facetAddress,
        bytes4 selector
    ) internal {
        require(
            facetAddress != address(0),
            "LibDiamondCut: Can't remove function that doesn't exist"
        );
        // an immutable function is a function defined directly in a diamond
        require(
            facetAddress != address(this),
            "LibDiamondCut: Can't remove immutable function"
        );
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds
            .selectorToFacetAndPosition[selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .facetFunctionSelectors[facetAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds
                .facetFunctionSelectors[facetAddress]
                .functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[facetAddress].functionSelectors[
                    selectorPosition
                ] = lastSelector;
            ds
                .selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds
                .facetFunctionSelectors[facetAddress]
                .facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[
                    lastFacetAddressPosition
                ];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address init, bytes memory data) internal {
        if (init == address(0)) {
            require(
                data.length == 0,
                "LibDiamondCut: init is address(0) butcalldata is not empty"
            );
        } else {
            require(
                data.length > 0,
                "LibDiamondCut: calldata is empty but init is not address(0)"
            );
            if (init != address(this)) {
                enforceHasContractCode(
                    init,
                    "LibDiamondCut: init address has no code"
                );
            }
            (bool success, bytes memory error) = init.delegatecall(data);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address target, string memory errorMessage)
        internal
        view
    {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(target)
        }
        require(contractSize > 0, errorMessage);
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}