// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {LibVersion} from "../libraries/LibVersion.sol";
import {LibAppStorage, AppStorage} from "../libraries/LibAppStorage.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

/**
 * @title VersionFacet
 * @author PartyFinance
 * @notice Facet that handles the unsupervised upgrades of Party's facets
 */
contract VersionFacet {
    event VersionDiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address updater
    );

    /**
     * @notice Retrieves the platform required state from the PartyFactory
     */
    function getRequiredState()
        internal
        view
        returns (address feeCollector, uint256 fee, address sentinel)
    {
        address factory = LibAppStorage.diamondStorage().platformFactory;
        (bool success, bytes memory data) = factory.staticcall(
            abi.encodeWithSignature("getPlatformInfo()")
        );
        require(success, "Failed retrieving facets from Factory");
        (feeCollector, fee, sentinel) = abi.decode(
            data,
            (address, uint256, address)
        );
    }

    /**
     * @notice Checks if the Party has the platform required state up-to-date
     * @dev Verifies the Party platform variables against the PartyFactory
     * @return areEqual Whether if the Party's Platform state is up-to-date
     */
    function checkEnsureState() external view returns (bool areEqual) {
        (
            address feeCollector,
            uint256 fee,
            address sentinel
        ) = getRequiredState();
        AppStorage storage s = LibAppStorage.diamondStorage();
        areEqual =
            feeCollector == s.platformFeeCollector &&
            fee == s.platformFee &&
            sentinel == s.platformSentinel;
    }

    /**
     * @notice Ensures that the Party platform variables are the same as the PartyFactory
     * @dev This will change the Platform Fee collector, Platform Fee and Platform Sentinel on the Party if needed
     */
    function ensureState() external {
        (
            address feeCollector,
            uint256 fee,
            address sentinel
        ) = getRequiredState();
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(
            feeCollector != s.platformFeeCollector ||
                fee != s.platformFee ||
                sentinel != s.platformSentinel,
            "Platform state on Party is already updated"
        );
        s.platformFeeCollector = feeCollector;
        s.platformFee = fee;
        s.platformSentinel = sentinel;
    }

    /**
     * @notice Retrieves the required cut established in the PartyFactory
     * @dev It excludes the DiamondCutFacet, since its handled after so that its always
     *      included as a required facet.
     */
    function getRequiredCut()
        internal
        view
        returns (IDiamondCut.FacetCut[] memory requiredCut)
    {
        address factory = LibAppStorage.diamondStorage().platformFactory;
        (bool success, bytes memory data) = factory.staticcall(
            abi.encodeWithSignature("getPartyDefaultFacetCut()")
        );
        require(success, "Failed retrieving facets from Factory");
        requiredCut = abi.decode(data, (IDiamondCut.FacetCut[]));
    }

    /**
     * @notice Checks if the Party need an upgrade (diamondCut)
     * @return areEqual If Party's facets are equal with required by the PartyFactory
     * @return currentFacets Current Party's facets
     * @return modelDiamondCut Required DiamondCut by the PartyFactory
     */
    function checkEnsureVersion()
        external
        view
        returns (
            bool areEqual,
            IDiamondLoupe.Facet[] memory currentFacets,
            IDiamondCut.FacetCut[] memory modelDiamondCut
        )
    {
        // Get current facets
        currentFacets = IDiamondLoupe(address(this)).facets();

        // Get required facets
        modelDiamondCut = getRequiredCut();

        // Diamond comparison
        areEqual = LibVersion.diamondEquals(currentFacets, modelDiamondCut);
    }

    /**
     * @notice Clones the functions from a Diamond model and overwrites the current Diamond functions
     * @dev Calling this function will guarantee that the function selectors are the same as the Diamond implementation
     */
    function ensureDiamond() external {
        // 1) Clear current function selectors
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        IDiamondCut.FacetCut[] memory removeCut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory selectors = new bytes4[](ds.selectorCount);
        uint256 selectorIndex;
        for (uint256 slotIndex; selectorIndex < ds.selectorCount; slotIndex++) {
            bytes32 slot = ds.selectorSlots[slotIndex];
            for (
                uint256 selectorSlotIndex;
                selectorSlotIndex < 8;
                selectorSlotIndex++
            ) {
                selectorIndex++;
                if (selectorIndex > ds.selectorCount) {
                    break;
                }
                bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));
                selectors[selectorIndex - 1] = selector;
            }
        }
        removeCut[0].action = IDiamondCut.FacetCutAction.Remove;
        removeCut[0].functionSelectors = selectors;
        LibDiamond.diamondCut(removeCut, address(0), "");

        // 2) Get the desired cut from the Diamond Model;
        IDiamondCut.FacetCut[] memory _modelCut = getRequiredCut();

        // 3) Overwrite the current function selectors with the Diamond Implementation
        LibDiamond.diamondCut(_modelCut, address(0), "");
        emit VersionDiamondCut(_modelCut, tx.origin);
    }
}