// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
pragma experimental ABIEncoderV2;

import {IDiamondCutCommon} from "./../interfaces/IDiamondCutCommon.sol";
import {IDiamondCut} from "./../interfaces/IDiamondCut.sol";
import {IDiamondCutBatchInit} from "./../interfaces/IDiamondCutBatchInit.sol";
import {IDiamondLoupe} from "./../interfaces/IDiamondLoupe.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {InterfaceDetectionStorage} from "./../../introspection/libraries/InterfaceDetectionStorage.sol";

/// @dev derived from https://github.com/mudgen/diamond-2 (MIT licence) and https://github.com/solidstate-network/solidstate-solidity (MIT licence)
library DiamondStorage {
    using Address for address;
    using DiamondStorage for DiamondStorage.Layout;
    using InterfaceDetectionStorage for InterfaceDetectionStorage.Layout;

    struct Layout {
        // selector => (facet address, selector slot position)
        mapping(bytes4 => bytes32) diamondFacets;
        // number of selectors registered in selectorSlots
        uint16 selectorCount;
        // array of selector slots with 8 selectors per slot
        mapping(uint256 => bytes32) selectorSlots;
    }

    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("animoca.core.Diamond.storage")) - 1);

    bytes32 internal constant CLEAR_ADDRESS_MASK = bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 internal constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    event DiamondCut(IDiamondCutCommon.FacetCut[] cuts, address target, bytes data);

    /// @notice Marks the following ERC165 interface(s) as supported: DiamondCut, DiamondCutBatchInit.
    function initDiamondCut() internal {
        InterfaceDetectionStorage.Layout storage interfaceDetectionLayout = InterfaceDetectionStorage.layout();
        interfaceDetectionLayout.setSupportedInterface(type(IDiamondCut).interfaceId, true);
        interfaceDetectionLayout.setSupportedInterface(type(IDiamondCutBatchInit).interfaceId, true);
    }

    /// @notice Marks the following ERC165 interface(s) as supported: DiamondLoupe.
    function initDiamondLoupe() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IDiamondLoupe).interfaceId, true);
    }

    function diamondCut(Layout storage s, IDiamondCutCommon.FacetCut[] memory cuts, address target, bytes memory data) internal {
        cutFacets(s, cuts);
        emit DiamondCut(cuts, target, data);
        initializationCall(target, data);
    }

    function diamondCut(
        Layout storage s,
        IDiamondCutCommon.FacetCut[] memory cuts,
        IDiamondCutCommon.Initialization[] memory initializations
    ) internal {
        unchecked {
            s.cutFacets(cuts);
            emit DiamondCut(cuts, address(0), "");
            uint256 length = initializations.length;
            for (uint256 i; i != length; ++i) {
                initializationCall(initializations[i].target, initializations[i].data);
            }
        }
    }

    function cutFacets(Layout storage s, IDiamondCutCommon.FacetCut[] memory facetCuts) internal {
        unchecked {
            uint256 originalSelectorCount = s.selectorCount;
            uint256 selectorCount = originalSelectorCount;
            bytes32 selectorSlot;

            // Check if last selector slot is not full
            if (selectorCount & 7 > 0) {
                // get last selectorSlot
                selectorSlot = s.selectorSlots[selectorCount >> 3];
            }

            uint256 length = facetCuts.length;
            for (uint256 i; i != length; ++i) {
                IDiamondCutCommon.FacetCut memory facetCut = facetCuts[i];
                IDiamondCutCommon.FacetCutAction action = facetCut.action;

                require(facetCut.selectors.length != 0, "Diamond: no function selectors");

                if (action == IDiamondCutCommon.FacetCutAction.ADD) {
                    (selectorCount, selectorSlot) = s.addFacetSelectors(selectorCount, selectorSlot, facetCut);
                } else if (action == IDiamondCutCommon.FacetCutAction.REPLACE) {
                    s.replaceFacetSelectors(facetCut);
                } else {
                    (selectorCount, selectorSlot) = s.removeFacetSelectors(selectorCount, selectorSlot, facetCut);
                }
            }

            if (selectorCount != originalSelectorCount) {
                s.selectorCount = uint16(selectorCount);
            }

            // If last selector slot is not full
            if (selectorCount & 7 > 0) {
                s.selectorSlots[selectorCount >> 3] = selectorSlot;
            }
        }
    }

    function addFacetSelectors(
        Layout storage s,
        uint256 selectorCount,
        bytes32 selectorSlot,
        IDiamondCutCommon.FacetCut memory facetCut
    ) internal returns (uint256, bytes32) {
        unchecked {
            if (facetCut.facet != address(this)) {
                // allows immutable functions to be added from a constructor
                require(facetCut.facet.isContract(), "Diamond: facet has no code"); // reverts if executed from a constructor
            }

            uint256 length = facetCut.selectors.length;
            for (uint256 i; i != length; ++i) {
                bytes4 selector = facetCut.selectors[i];
                bytes32 oldFacet = s.diamondFacets[selector];

                require(address(bytes20(oldFacet)) == address(0), "Diamond: selector already added");

                // add facet for selector
                s.diamondFacets[selector] = bytes20(facetCut.facet) | bytes32(selectorCount);
                uint256 selectorInSlotPosition = (selectorCount & 7) << 5;

                // clear selector position in slot and add selector
                selectorSlot = (selectorSlot & ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) | (bytes32(selector) >> selectorInSlotPosition);

                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    s.selectorSlots[selectorCount >> 3] = selectorSlot;
                    selectorSlot = 0;
                }

                ++selectorCount;
            }

            return (selectorCount, selectorSlot);
        }
    }

    function removeFacetSelectors(
        Layout storage s,
        uint256 selectorCount,
        bytes32 selectorSlot,
        IDiamondCutCommon.FacetCut memory facetCut
    ) internal returns (uint256, bytes32) {
        unchecked {
            require(facetCut.facet == address(0), "Diamond: non-zero address facet");

            uint256 selectorSlotCount = selectorCount >> 3;
            uint256 selectorInSlotIndex = selectorCount & 7;

            for (uint256 i; i != facetCut.selectors.length; ++i) {
                bytes4 selector = facetCut.selectors[i];
                bytes32 oldFacet = s.diamondFacets[selector];

                require(address(bytes20(oldFacet)) != address(0), "Diamond: selector not found");
                require(address(bytes20(oldFacet)) != address(this), "Diamond: immutable function");

                if (selectorSlot == 0) {
                    selectorSlotCount--;
                    selectorSlot = s.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }

                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;

                // adding a block here prevents stack too deep error
                {
                    // replace selector with last selector in l.facets
                    lastSelector = bytes4(selectorSlot << (selectorInSlotIndex << 5));

                    if (lastSelector != selector) {
                        // update last selector slot position info
                        s.diamondFacets[lastSelector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(s.diamondFacets[lastSelector]);
                    }

                    delete s.diamondFacets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }

                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = s.selectorSlots[oldSelectorsSlotCount];

                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot =
                        (oldSelectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);

                    // update storage with the modified slot
                    s.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    selectorSlot =
                        (selectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }

                if (selectorInSlotIndex == 0) {
                    delete s.selectorSlots[selectorSlotCount];
                    selectorSlot = 0;
                }
            }

            selectorCount = (selectorSlotCount << 3) | selectorInSlotIndex;

            return (selectorCount, selectorSlot);
        }
    }

    function replaceFacetSelectors(Layout storage s, IDiamondCutCommon.FacetCut memory facetCut) internal {
        unchecked {
            require(facetCut.facet.isContract(), "Diamond: facet has no code");

            uint256 length = facetCut.selectors.length;
            for (uint256 i; i != length; ++i) {
                bytes4 selector = facetCut.selectors[i];
                bytes32 oldFacet = s.diamondFacets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));

                require(oldFacetAddress != address(0), "Diamond: selector not found");
                require(oldFacetAddress != address(this), "Diamond: immutable function");
                require(oldFacetAddress != facetCut.facet, "Diamond: identical function");

                // replace old facet address
                s.diamondFacets[selector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(facetCut.facet);
            }
        }
    }

    function initializationCall(address target, bytes memory data) internal {
        if (target == address(0)) {
            require(data.length == 0, "Diamond: data is not empty");
        } else {
            require(data.length != 0, "Diamond: data is empty");
            if (target != address(this)) {
                require(target.isContract(), "Diamond: target has no code");
            }

            (bool success, bytes memory returndata) = target.delegatecall(data);
            if (!success) {
                uint256 returndataLength = returndata.length;
                if (returndataLength != 0) {
                    assembly {
                        revert(add(32, returndata), returndataLength)
                    }
                } else {
                    revert("Diamond: init call reverted");
                }
            }
        }
    }

    function facets(Layout storage s) internal view returns (IDiamondLoupe.Facet[] memory diamondFacets) {
        unchecked {
            uint16 selectorCount = s.selectorCount;
            diamondFacets = new IDiamondLoupe.Facet[](selectorCount);

            uint256[] memory numFacetSelectors = new uint256[](selectorCount);
            uint256 numFacets;
            uint256 selectorIndex;

            // loop through function selectors
            for (uint256 slotIndex; selectorIndex < selectorCount; ++slotIndex) {
                bytes32 slot = s.selectorSlots[slotIndex];

                for (uint256 selectorSlotIndex; selectorSlotIndex != 8; ++selectorSlotIndex) {
                    ++selectorIndex;

                    if (selectorIndex > selectorCount) {
                        break;
                    }

                    bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));
                    address facet = address(bytes20(s.diamondFacets[selector]));

                    bool continueLoop;

                    for (uint256 facetIndex; facetIndex != numFacets; ++facetIndex) {
                        if (diamondFacets[facetIndex].facet == facet) {
                            diamondFacets[facetIndex].selectors[numFacetSelectors[facetIndex]] = selector;
                            ++numFacetSelectors[facetIndex];
                            continueLoop = true;
                            break;
                        }
                    }

                    if (continueLoop) {
                        continue;
                    }

                    diamondFacets[numFacets].facet = facet;
                    diamondFacets[numFacets].selectors = new bytes4[](selectorCount);
                    diamondFacets[numFacets].selectors[0] = selector;
                    numFacetSelectors[numFacets] = 1;
                    ++numFacets;
                }
            }

            for (uint256 facetIndex; facetIndex != numFacets; ++facetIndex) {
                uint256 numSelectors = numFacetSelectors[facetIndex];
                bytes4[] memory selectors = diamondFacets[facetIndex].selectors;

                // setting the number of selectors
                assembly {
                    mstore(selectors, numSelectors)
                }
            }

            // setting the number of facets
            assembly {
                mstore(diamondFacets, numFacets)
            }
        }
    }

    function facetFunctionSelectors(Layout storage s, address facet) internal view returns (bytes4[] memory selectors) {
        unchecked {
            uint16 selectorCount = s.selectorCount;
            selectors = new bytes4[](selectorCount);

            uint256 numSelectors;
            uint256 selectorIndex;

            // loop through function selectors
            for (uint256 slotIndex; selectorIndex < selectorCount; ++slotIndex) {
                bytes32 slot = s.selectorSlots[slotIndex];

                for (uint256 selectorSlotIndex; selectorSlotIndex != 8; ++selectorSlotIndex) {
                    ++selectorIndex;

                    if (selectorIndex > selectorCount) {
                        break;
                    }

                    bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));

                    if (facet == address(bytes20(s.diamondFacets[selector]))) {
                        selectors[numSelectors] = selector;
                        ++numSelectors;
                    }
                }
            }

            // set the number of selectors in the array
            assembly {
                mstore(selectors, numSelectors)
            }
        }
    }

    function facetAddresses(Layout storage s) internal view returns (address[] memory addresses) {
        unchecked {
            uint16 selectorCount = s.selectorCount;
            addresses = new address[](selectorCount);
            uint256 numFacets;
            uint256 selectorIndex;

            for (uint256 slotIndex; selectorIndex < selectorCount; ++slotIndex) {
                bytes32 slot = s.selectorSlots[slotIndex];

                for (uint256 selectorSlotIndex; selectorSlotIndex != 8; ++selectorSlotIndex) {
                    ++selectorIndex;

                    if (selectorIndex > selectorCount) {
                        break;
                    }

                    bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));
                    address facet = address(bytes20(s.diamondFacets[selector]));

                    bool continueLoop;

                    for (uint256 facetIndex; facetIndex != numFacets; ++facetIndex) {
                        if (facet == addresses[facetIndex]) {
                            continueLoop = true;
                            break;
                        }
                    }

                    if (continueLoop) {
                        continue;
                    }

                    addresses[numFacets] = facet;
                    ++numFacets;
                }
            }

            // set the number of facet addresses in the array
            assembly {
                mstore(addresses, numFacets)
            }
        }
    }

    function facetAddress(Layout storage s, bytes4 selector) internal view returns (address facet) {
        facet = address(bytes20(s.diamondFacets[selector]));
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }
}