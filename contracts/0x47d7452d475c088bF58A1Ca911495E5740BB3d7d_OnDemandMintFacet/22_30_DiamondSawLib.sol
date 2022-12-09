// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IDiamondCut} from "../facets/DiamondClone/IDiamondCut.sol";

library DiamondSawLib {
    bytes32 constant DIAMOND_SAW_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.saw.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondSawStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a facet implements a given interface
        // Note: this works because no interface can be implemented by
        // two different facets with diamond saw because no
        // selector overlap is permitted!!
        mapping(bytes4 => address) interfaceToFacet;
        // for transfer hooks, selectors must be approved in the saw
        mapping(bytes4 => bool) approvedTransferHookFunctionSelectors;
        // for tokenURI overrides, selectors must be approved in the saw
        mapping(bytes4 => bool) approvedTokenURIFunctionSelectors;
        // Saw contracts which clients can upgrade to
        mapping(address => bool) supportedSawAddresses;
    }

    function diamondSawStorage()
        internal
        pure
        returns (DiamondSawStorage storage ds)
    {
        bytes32 position = DIAMOND_SAW_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    // Internal function version of diamondCut
    // only supports adding new selectors
    function diamondCutAddOnly(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
            require(
                _diamondCut[facetIndex].action ==
                    IDiamondCut.FacetCutAction.Add,
                "Only add action supported in saw"
            );
            require(
                !isFacetSupported(_diamondCut[facetIndex].facetAddress),
                "Facet already exists in saw"
            );
            addFunctions(
                _diamondCut[facetIndex].facetAddress,
                _diamondCut[facetIndex].functionSelectors
            );
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondSawStorage storage ds = diamondSawStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;

            require(
                oldFacetAddress == address(0),
                "Cannot add function that already exists"
            );
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function addFacet(DiamondSawStorage storage ds, address _facetAddress)
        internal
    {
        enforceHasContractCode(
            _facetAddress,
            "LibDiamondCut: New facet has no code"
        );
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds
            .facetAddresses
            .length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondSawStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
            _selector
        );
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function initializeDiamondCut(address _init, bytes memory _calldata)
        internal
    {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                "LibDiamondCut: _init is address(0) but_calldata is not empty"
            );
        } else {
            require(
                _calldata.length > 0,
                "LibDiamondCut: _calldata is empty but _init is not address(0)"
            );
            if (_init != address(this)) {
                enforceHasContractCode(
                    _init,
                    "LibDiamondCut: _init address has no code"
                );
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

    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }

    function setFacetSupportsInterface(bytes4 _interface, address _facetAddress)
        internal
    {
        checkFacetSupported(_facetAddress);
        DiamondSawStorage storage ds = diamondSawStorage();
        ds.interfaceToFacet[_interface] = _facetAddress;
    }

    function isFacetSupported(address _facetAddress)
        internal
        view
        returns (bool)
    {
        return
            diamondSawStorage()
                .facetFunctionSelectors[_facetAddress]
                .functionSelectors
                .length > 0;
    }

    function checkFacetSupported(address _facetAddress) internal view {
        require(isFacetSupported(_facetAddress), "Facet not supported");
    }

    function approveTransferHookSelector(bytes4 transferHookSelector) internal {
        DiamondSawStorage storage s = diamondSawStorage();
        address facetImplementation = s
            .selectorToFacetAndPosition[transferHookSelector]
            .facetAddress;

        require(
            facetImplementation != address(0),
            "Cannot set transfer hook to unsupported selector"
        );

        s.approvedTransferHookFunctionSelectors[transferHookSelector] = true;
    }

    function approveTokenURISelector(bytes4 tokenURISelector) internal {
        DiamondSawStorage storage s = diamondSawStorage();
        address facetImplementation = s
            .selectorToFacetAndPosition[tokenURISelector]
            .facetAddress;
        require(
            facetImplementation != address(0),
            "Cannot set token uri override to unsupported selector"
        );
        s.approvedTokenURIFunctionSelectors[tokenURISelector] = true;
    }

    function setUpgradeSawAddress(address _upgradeSaw) internal {
        diamondSawStorage().supportedSawAddresses[_upgradeSaw] = true;
    }
}