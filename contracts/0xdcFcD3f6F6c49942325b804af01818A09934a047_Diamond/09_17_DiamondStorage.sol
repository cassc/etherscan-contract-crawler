// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import "../diamond/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

error ErrDiamondFacetAlreadyExists(address facet, bytes4 selector);
error ErrDiamondFacetSameFunction(address facet, bytes4 selector);

library DiamondStorage {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct Layout {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            l.slot := position
        }
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        // require(
        //     _functionSelectors.length > 0,
        //     "LibDiamondCut: No selectors in facet to cut"
        // );
        Layout storage l = layout();
        // require(
        //     _facetAddress != address(0),
        //     "LibDiamondCut: Add facet can't be address(0)"
        // );
        uint96 selectorPosition = uint96(l.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(l, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = l.selectorToFacetAndPosition[selector].facetAddress;

            if (oldFacetAddress != address(0)) {
                revert ErrDiamondFacetAlreadyExists(oldFacetAddress, selector);
            }

            addFunction(l, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        // require(
        //     _functionSelectors.length > 0,
        //     "LibDiamondCut: No selectors in facet to cut"
        // );
        Layout storage l = layout();
        // require(
        //     _facetAddress != address(0),
        //     "LibDiamondCut: Add facet can't be address(0)"
        // );
        uint96 selectorPosition = uint96(l.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(l, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = l.selectorToFacetAndPosition[selector].facetAddress;

            if (oldFacetAddress == _facetAddress) {
                revert ErrDiamondFacetSameFunction(oldFacetAddress, selector);
            }

            removeFunction(l, oldFacetAddress, selector);
            addFunction(l, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address, bytes4[] memory _functionSelectors) internal {
        // require(
        //     _functionSelectors.length > 0,
        //     "LibDiamondCut: No selectors in facet to cut"
        // );
        Layout storage l = layout();
        // if function does not exist then do nothing and return
        // require(
        //     _facetAddress == address(0),
        //     "LibDiamondCut: Remove facet address must be address(0)"
        // );
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = l.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(l, oldFacetAddress, selector);
        }
    }

    function addFacet(Layout storage l, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        l.facetFunctionSelectors[_facetAddress].facetAddressPosition = l.facetAddresses.length;
        l.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        Layout storage l,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        l.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        l.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        l.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(
        Layout storage l,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        // require(
        //     _facetAddress != address(0),
        //     "LibDiamondCut: Can't remove function that doesn't exist"
        // );
        // an immutable function is a function defined directly in a diamond
        // require(
        //     _facetAddress != address(this),
        //     "LibDiamondCut: Can't remove immutable function"
        // );
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = l.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = l.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = l.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            l.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            l.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        l.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete l.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = l.facetAddresses.length - 1;
            uint256 facetAddressPosition = l.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = l.facetAddresses[lastFacetAddressPosition];
                l.facetAddresses[facetAddressPosition] = lastFacetAddress;
                l.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            l.facetAddresses.pop();
            delete l.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}