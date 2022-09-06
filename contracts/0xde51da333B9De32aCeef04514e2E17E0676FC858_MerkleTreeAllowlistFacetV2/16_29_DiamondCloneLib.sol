// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DiamondSaw} from "../../DiamondSaw.sol";
import {IDiamondLoupe} from "./IDiamondLoupe.sol";
import {IDiamondCut} from "./IDiamondCut.sol";

library DiamondCloneLib {
    bytes32 constant DIAMOND_CLONE_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.clone.storage");

    bytes32 constant ERC721A_STORAGE_POSITION =
        keccak256("erc721a.facet.storage");

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    struct DiamondCloneStorage {
        // address of the diamond saw contract
        address diamondSawAddress;
        // mapping to all the facets this diamond implements.
        mapping(address => bool) facetAddresses;
        // number of facets supported
        uint256 numFacets;
        // optional gas cache for highly trafficked write selectors
        mapping(bytes4 => address) selectorGasCache;
        // immutability window
        uint256 immutableUntilBlock;
    }

    // minimal copy  of ERC721AStorage for initialization
    struct ERC721AStorage {
        // The tokenId of the next token to be minted.
        uint256 _currentIndex;
    }

    function diamondCloneStorage()
        internal
        pure
        returns (DiamondCloneStorage storage s)
    {
        bytes32 position = DIAMOND_CLONE_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    // calls externally to the saw to find the appropriate facet to delegate to
    function _getFacetAddressForCall() internal view returns (address addr) {
        DiamondCloneStorage storage s = diamondCloneStorage();

        addr = s.selectorGasCache[msg.sig];
        if (addr != address(0)) {
            return addr;
        }

        (bool success, bytes memory res) = s.diamondSawAddress.staticcall(
            abi.encodeWithSelector(0x14bc7560, msg.sig)
        );
        require(success, "Failed to fetch facet address for call");

        assembly {
            addr := mload(add(res, 32))
        }

        return s.facetAddresses[addr] ? addr : address(0);
    }

    function initNFT() internal {
        ERC721AStorage storage es;
        bytes32 position = ERC721A_STORAGE_POSITION;
        assembly {
            es.slot := position
        }

        es._currentIndex = 1;
    }

    function initializeDiamondClone(
        address diamondSawAddress,
        address[] calldata _facetAddresses
    ) internal {
        DiamondCloneLib.DiamondCloneStorage storage s = DiamondCloneLib
            .diamondCloneStorage();

        require(diamondSawAddress != address(0), "Must set saw addy");
        require(s.diamondSawAddress == address(0), "Already inited");

        initNFT();

        s.diamondSawAddress = diamondSawAddress;
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](
            _facetAddresses.length
        );

        // emit the diamond cut event
        for (uint256 i; i < _facetAddresses.length; i++) {
            address facetAddress = _facetAddresses[i];
            bytes4[] memory selectors = DiamondSaw(diamondSawAddress)
                .functionSelectorsForFacetAddress(facetAddress);
            require(selectors.length > 0, "Facet is not supported by the saw");
            cuts[i].facetAddress = _facetAddresses[i];
            cuts[i].functionSelectors = selectors;
            s.facetAddresses[facetAddress] = true;
        }

        emit DiamondCut(cuts, address(0), "");

        s.numFacets = _facetAddresses.length;
    }

    function _purgeGasCache(bytes4[] memory selectors) internal {
        DiamondCloneStorage storage s = diamondCloneStorage();

        for (uint256 i; i < selectors.length; i++) {
            if (s.selectorGasCache[selectors[i]] != address(0)) {
                delete s.selectorGasCache[selectors[i]];
            }
        }
    }

    function cutWithDiamondSaw(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes calldata _calldata
    ) internal {
        DiamondCloneStorage storage s = diamondCloneStorage();

        uint256 newNumFacets = s.numFacets;

        // emit the diamond cut event
        for (uint256 i; i < _diamondCut.length; i++) {
            IDiamondCut.FacetCut memory cut = _diamondCut[i];
            bytes4[] memory selectors = DiamondSaw(s.diamondSawAddress)
                .functionSelectorsForFacetAddress(cut.facetAddress);

            require(selectors.length > 0, "Facet is not supported by the saw");
            require(
                selectors.length == cut.functionSelectors.length,
                "You can only modify all selectors at once with diamond saw"
            );

            // NOTE we override the passed selectors after validating the length matches
            // With diamond saw we can only add / remove all selectors for a given facet
            cut.functionSelectors = selectors;

            // if the address is already in the facet map
            // remove it and remove all the selectors
            // otherwise add the selectors
            if (s.facetAddresses[cut.facetAddress]) {
                require(
                    cut.action == IDiamondCut.FacetCutAction.Remove,
                    "Can only remove existing facet selectors"
                );
                delete s.facetAddresses[cut.facetAddress];
                _purgeGasCache(selectors);
                newNumFacets -= 1;
            } else {
                require(
                    cut.action == IDiamondCut.FacetCutAction.Add,
                    "Can only add non-existing facet selectors"
                );
                s.facetAddresses[cut.facetAddress] = true;
                newNumFacets += 1;
            }
        }

        emit DiamondCut(_diamondCut, _init, _calldata);

        // call the init function
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up the error
                revert(string(error));
            } else {
                revert("DiamondCloneLib: _init function reverted");
            }
        }

        s.numFacets = newNumFacets;
    }

    function upgradeDiamondSaw(
        address _upgradeSawAddress,
        address[] calldata _oldFacetAddresses,
        address[] calldata _newFacetAddresses,
        address _init,
        bytes calldata _calldata
    ) internal {
        require(
            !isImmutable(),
            "Cannot upgrade saw during immutability window"
        );
        require(
            _upgradeSawAddress != address(0),
            "Cannot set saw to zero address"
        );

        DiamondCloneStorage storage s = diamondCloneStorage();

        require(
            _oldFacetAddresses.length == s.numFacets,
            "Must remove all facets to upgrade saw"
        );

        DiamondSaw oldSawInstance = DiamondSaw(s.diamondSawAddress);

        require(
            oldSawInstance.isUpgradeSawSupported(_upgradeSawAddress),
            "Upgrade saw is not supported"
        );
        DiamondSaw newSawInstance = DiamondSaw(_upgradeSawAddress);

        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](
            _oldFacetAddresses.length + _newFacetAddresses.length
        );

        for (
            uint256 i;
            i < _oldFacetAddresses.length + _newFacetAddresses.length;
            i++
        ) {
            if (i < _oldFacetAddresses.length) {
                address facetAddress = _oldFacetAddresses[i];
                require(
                    s.facetAddresses[facetAddress],
                    "Cannot remove facet that is not supported"
                );
                bytes4[] memory selectors = oldSawInstance
                    .functionSelectorsForFacetAddress(facetAddress);
                require(
                    selectors.length > 0,
                    "Facet is not supported by the saw"
                );

                cuts[i].action = IDiamondCut.FacetCutAction.Remove;
                cuts[i].facetAddress = facetAddress;
                cuts[i].functionSelectors = selectors;

                _purgeGasCache(selectors);
                delete s.facetAddresses[facetAddress];
            } else {
                address facetAddress = _newFacetAddresses[
                    i - _oldFacetAddresses.length
                ];
                bytes4[] memory selectors = newSawInstance
                    .functionSelectorsForFacetAddress(facetAddress);
                require(
                    selectors.length > 0,
                    "Facet is not supported by the new saw"
                );

                cuts[i].action = IDiamondCut.FacetCutAction.Add;
                cuts[i].facetAddress = facetAddress;
                cuts[i].functionSelectors = selectors;

                s.facetAddresses[facetAddress] = true;
            }
        }

        emit DiamondCut(cuts, _init, _calldata);

        // actually update the diamond saw address
        s.numFacets = _newFacetAddresses.length;
        s.diamondSawAddress = _upgradeSawAddress;

        // call the init function
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up the error
                revert(string(error));
            } else {
                revert("DiamondCloneLib: _init function reverted");
            }
        }
    }

    function setGasCacheForSelector(bytes4 selector) internal {
        DiamondCloneStorage storage s = diamondCloneStorage();

        address facetAddress = DiamondSaw(s.diamondSawAddress)
            .facetAddressForSelector(selector);
        require(facetAddress != address(0), "Facet not supported");
        require(s.facetAddresses[facetAddress], "Facet not included in clone");

        s.selectorGasCache[selector] = facetAddress;
    }

    function setImmutableUntilBlock(uint256 blockNum) internal {
        diamondCloneStorage().immutableUntilBlock = blockNum;
    }

    function isImmutable() internal view returns (bool) {
        return block.number < diamondCloneStorage().immutableUntilBlock;
    }

    function immutableUntilBlock() internal view returns (uint256) {
        return diamondCloneStorage().immutableUntilBlock;
    }

    /**
     * LOUPE FUNCTIONALITY BELOW
     */

    function facets()
        internal
        view
        returns (IDiamondLoupe.Facet[] memory facets_)
    {
        DiamondCloneLib.DiamondCloneStorage storage ds = DiamondCloneLib
            .diamondCloneStorage();
        IDiamondLoupe.Facet[] memory allSawFacets = DiamondSaw(
            ds.diamondSawAddress
        ).allFacetsWithSelectors();

        uint256 copyIndex = 0;

        facets_ = new IDiamondLoupe.Facet[](ds.numFacets);

        for (uint256 i; i < allSawFacets.length; i++) {
            if (ds.facetAddresses[allSawFacets[i].facetAddress]) {
                facets_[copyIndex] = allSawFacets[i];
                copyIndex++;
            }
        }
    }

    function facetAddresses()
        internal
        view
        returns (address[] memory facetAddresses_)
    {
        DiamondCloneLib.DiamondCloneStorage storage ds = DiamondCloneLib
            .diamondCloneStorage();

        address[] memory allSawFacetAddresses = DiamondSaw(ds.diamondSawAddress)
            .allFacetAddresses();
        facetAddresses_ = new address[](ds.numFacets);

        uint256 copyIndex = 0;

        for (uint256 i; i < allSawFacetAddresses.length; i++) {
            if (ds.facetAddresses[allSawFacetAddresses[i]]) {
                facetAddresses_[copyIndex] = allSawFacetAddresses[i];
                copyIndex++;
            }
        }
    }
}