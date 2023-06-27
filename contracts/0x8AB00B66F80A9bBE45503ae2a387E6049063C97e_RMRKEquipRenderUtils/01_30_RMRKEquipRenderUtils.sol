// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

import "./RMRKRenderUtils.sol";
import "./RMRKMultiAssetRenderUtils.sol";
import "./RMRKNestableRenderUtils.sol";
import "../catalog/IRMRKCatalog.sol";
import "../equippable/IERC6220.sol";
import "../nestable/IERC6059.sol";
import "../library/RMRKLib.sol";
import "../library/RMRKErrors.sol";

/**
 * @title RMRKEquipRenderUtils
 * @author RMRK team
 * @notice Smart contract of the RMRK Equip render utils module.
 * @dev Extra utility functions for composing RMRK extended assets.
 */
contract RMRKEquipRenderUtils is
    RMRKRenderUtils,
    RMRKMultiAssetRenderUtils,
    RMRKNestableRenderUtils
{
    using RMRKLib for uint64[];

    /**
     * @notice The structure used to display a full information of an active asset.
     * @return id ID of the asset
     * @return equppableGroupId ID of the equippable group this asset belongs to
     * @return priority Priority of the asset in the active assets array it belongs to
     * @return catalogAddress Address of the `Catalog` smart contract this asset belongs to
     * @return metadata Metadata URI of the asset
     * @return partIds[] An array of IDs of fixed and slot parts present in the asset
     */
    struct ExtendedEquippableActiveAsset {
        uint64 id;
        uint64 equippableGroupId;
        uint64 priority;
        address catalogAddress;
        string metadata;
        uint64[] partIds;
    }

    /**
     * @notice The structure used to display a full information of a pending asset.
     * @return id ID of the asset
     * @return equppableGroupId ID of the equippable group this asset belongs to
     * @return acceptRejectIndex The index of the given asset in the pending assets array it belongs to
     * @return replacesAssetWithId ID of the asset the given asset will replace if accepted
     * @return catalogAddress Address of the `Catalog` smart contract this asset belongs to
     * @return metadata Metadata URI of the asset
     * @return partIds[] An array of IDs of fixed and slot parts present in the asset
     */
    struct ExtendedPendingAsset {
        uint64 id;
        uint64 equippableGroupId;
        uint128 acceptRejectIndex;
        uint64 replacesAssetWithId;
        address catalogAddress;
        string metadata;
        uint64[] partIds;
    }

    /**
     * @notice The structure used to display a full information of an equippend slot part.
     * @return partId ID of the slot part
     * @return childAssetId ID of the child asset equipped into the slot part
     * @return z The z value of the part defining how it should be rendered when presenting the full NFT
     * @return childAddress Address of the collection smart contract of the child token equipped into the slot
     * @return childId ID of the child token equipped into the slot
     * @return childAssetMetadata Metadata URI of the child token equipped into the slot
     * @return partMetadata Metadata URI of the given slot part
     */
    struct EquippedSlotPart {
        uint64 partId;
        uint64 childAssetId;
        uint8 z; //1 byte
        address childAddress;
        uint256 childId;
        string childAssetMetadata; //n bytes 32+
        string partMetadata; //n bytes 32+
    }

    /**
     * @notice Used to provide data about fixed parts.
     * @return partId ID of the part
     * @return z The z value of the asset, specifying how the part should be rendered in a composed NFT
     * @return matadataURI The metadata URI of the fixed part
     */
    struct FixedPart {
        uint64 partId;
        uint8 z; //1 byte
        string metadataURI; //n bytes 32+
    }

    /**
     * @notice The structure used to represent an asset with a Slot.
     * @return slotPartId ID of the Slot part
     * @return childAssetId ID of the child asset which is equippable into the slot part
     * @return parentAssetId ID of the parent asset which can receive the slot part
     * @return priority Priority of the asset on the active assets list
     * @return parentCatalogAddress Catalog address of the parent asset
     * @return isEquipped Whether the asset is currently equipped into the slot part or not
     * @return partMetadata Metadata URI of the given slot part
     * @return childAssetMetadata Metadata URI of the child asset
     * @return parentAssetMetadata Metadata URI of the parent asset
     */
    struct EquippableData {
        uint64 slotPartId;
        uint64 childAssetId;
        uint64 parentAssetId;
        uint64 priority;
        address parentCatalogAddress;
        bool isEquipped;
        string partMetadata;
        string childAssetMetadata;
        string parentAssetMetadata;
    }

    struct ChildWithTopAssetMetadata {
        address contractAddress;
        uint256 tokenId;
        string metadata;
    }

    /**
     * @notice Used to get extended active assets of the given token.
     * @dev The full `ExtendedEquippableActiveAsset` looks like this:
     *  [
     *      ID,
     *      equippableGroupId,
     *      priority,
     *      catalogAddress,
     *      metadata,
     *      [
     *          fixedPartId0,
     *          fixedPartId1,
     *          fixedPartId2,
     *          slotPartId0,
     *          slotPartId1,
     *          slotPartId2
     *      ]
     *  ]
     * @param target Address of the smart contract of the given token
     * @param tokenId ID of the token to retrieve the extended active assets for
     * @return An array of ExtendedEquippableActiveAssets present on the given token
     */
    function getExtendedEquippableActiveAssets(
        address target,
        uint256 tokenId
    ) public view virtual returns (ExtendedEquippableActiveAsset[] memory) {
        IERC6220 target_ = IERC6220(target);

        uint64[] memory assets = target_.getActiveAssets(tokenId);
        uint64[] memory priorities = target_.getActiveAssetPriorities(tokenId);
        uint256 len = assets.length;
        if (len == uint256(0)) {
            revert RMRKTokenHasNoAssets();
        }

        ExtendedEquippableActiveAsset[]
            memory activeAssets = new ExtendedEquippableActiveAsset[](len);

        for (uint256 i; i < len; ) {
            (
                string memory metadataURI,
                uint64 equippableGroupId,
                address catalogAddress,
                uint64[] memory partIds
            ) = target_.getAssetAndEquippableData(tokenId, assets[i]);
            activeAssets[i] = ExtendedEquippableActiveAsset({
                id: assets[i],
                equippableGroupId: equippableGroupId,
                priority: priorities[i],
                catalogAddress: catalogAddress,
                metadata: metadataURI,
                partIds: partIds
            });
            unchecked {
                ++i;
            }
        }
        return activeAssets;
    }

    /**
     * @notice Used to get the extended pending assets of the given token.
     * @dev The full `ExtendedPendingAsset` looks like this:
     *  [
     *      ID,
     *      equippableGroupId,
     *      acceptRejectIndex,
     *      replacesAssetWithId,
     *      catalogAddress,
     *      metadata,
     *      [
     *          fixedPartId0,
     *          fixedPartId1,
     *          fixedPartId2,
     *          slotPartId0,
     *          slotPartId1,
     *          slotPartId2
     *      ]
     *  ]
     * @param target Address of the smart contract of the given token
     * @param tokenId ID of the token to retrieve the extended pending assets for
     * @return An array of ExtendedPendingAssets present on the given token
     */
    function getExtendedPendingAssets(
        address target,
        uint256 tokenId
    ) public view virtual returns (ExtendedPendingAsset[] memory) {
        IERC6220 target_ = IERC6220(target);

        uint64[] memory assets = target_.getPendingAssets(tokenId);
        uint256 len = assets.length;
        if (len == uint256(0)) {
            revert RMRKTokenHasNoAssets();
        }

        ExtendedPendingAsset[]
            memory pendingAssets = new ExtendedPendingAsset[](len);
        uint64 replacesAssetWithId;
        for (uint256 i; i < len; ) {
            (
                string memory metadataURI,
                uint64 equippableGroupId,
                address catalogAddress,
                uint64[] memory partIds
            ) = target_.getAssetAndEquippableData(tokenId, assets[i]);
            replacesAssetWithId = target_.getAssetReplacements(
                tokenId,
                assets[i]
            );
            pendingAssets[i] = ExtendedPendingAsset({
                id: assets[i],
                equippableGroupId: equippableGroupId,
                acceptRejectIndex: uint128(i),
                replacesAssetWithId: replacesAssetWithId,
                catalogAddress: catalogAddress,
                metadata: metadataURI,
                partIds: partIds
            });
            unchecked {
                ++i;
            }
        }
        return pendingAssets;
    }

    /**
     * @notice Used to retrieve the equipped parts of the given token.
     * @dev NOTE: Some of the equipped children might be empty.
     * @dev The full `Equipment` struct looks like this:
     *  [
     *      assetId,
     *      childAssetId,
     *      childId,
     *      childEquippableAddress
     *  ]
     * @param target Address of the smart contract of the given token
     * @param tokenId ID of the token to retrieve the equipped items in the asset for
     * @param assetId ID of the asset being queried for equipped parts
     * @return slotPartIds An array of the IDs of the slot parts present in the given asset
     * @return childrenEquipped An array of `Equipment` structs containing info about the equipped children
     * @return childrenAssetMetadata An array of strings corresponding to asset metadata of the equipped children
     */
    function getEquipped(
        address target,
        uint64 tokenId,
        uint64 assetId
    )
        public
        view
        returns (
            uint64[] memory slotPartIds,
            IERC6220.Equipment[] memory childrenEquipped,
            string[] memory childrenAssetMetadata
        )
    {
        IERC6220 target_ = IERC6220(target);

        (, , address catalogAddress, uint64[] memory partIds) = target_
            .getAssetAndEquippableData(tokenId, assetId);

        (slotPartIds, ) = splitSlotAndFixedParts(partIds, catalogAddress);
        uint256 len = slotPartIds.length;

        childrenEquipped = new IERC6220.Equipment[](len);
        childrenAssetMetadata = new string[](len);

        for (uint256 i; i < len; ) {
            IERC6220.Equipment memory equipment = target_.getEquipment(
                tokenId,
                catalogAddress,
                slotPartIds[i]
            );
            if (equipment.assetId == assetId) {
                childrenEquipped[i] = equipment;
                childrenAssetMetadata[i] = IERC6220(
                    equipment.childEquippableAddress
                ).getAssetMetadata(equipment.childId, equipment.childAssetId);
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Used to compose the given equippables.
     * @dev The full `FixedPart` struct looks like this:
     *  [
     *      partId,
     *      z,
     *      metadataURI
     *  ]
     * @dev The full `EquippedSlotPart` struct looks like this:
     *  [
     *      partId,
     *      childAssetId,
     *      z,
     *      childAddress,
     *      childId,
     *      childAssetMetadata,
     *      partMetadata
     *  ]
     * @param target Address of the smart contract of the given token
     * @param tokenId ID of the token to compose the equipped items in the asset for
     * @param assetId ID of the asset being queried for equipped parts
     * @return metadataURI Metadata URI of the asset
     * @return equippableGroupId Equippable group ID of the asset
     * @return catalogAddress Address of the catalog to which the asset belongs to
     * @return fixedParts An array of fixed parts respresented by the `FixedPart` structs present on the asset
     * @return slotParts An array of slot parts represented by the `EquippedSlotPart` structs present on the asset
     */
    function composeEquippables(
        address target,
        uint256 tokenId,
        uint64 assetId
    )
        public
        view
        returns (
            string memory metadataURI,
            uint64 equippableGroupId,
            address catalogAddress,
            FixedPart[] memory fixedParts,
            EquippedSlotPart[] memory slotParts
        )
    {
        IERC6220 target_ = IERC6220(target);
        uint64[] memory partIds;

        // If token does not have uint64[] memory slotPartId to save the asset, it would fail here.
        (metadataURI, equippableGroupId, catalogAddress, partIds) = target_
            .getAssetAndEquippableData(tokenId, assetId);
        if (catalogAddress == address(0)) revert RMRKNotComposableAsset();

        (
            uint64[] memory slotPartIds,
            uint64[] memory fixedPartIds
        ) = splitSlotAndFixedParts(partIds, catalogAddress);

        // Fixed parts:
        fixedParts = new FixedPart[](fixedPartIds.length);

        uint256 len = fixedPartIds.length;
        if (len != 0) {
            IRMRKCatalog.Part[] memory catalogFixedParts = IRMRKCatalog(
                catalogAddress
            ).getParts(fixedPartIds);
            for (uint256 i; i < len; ) {
                fixedParts[i] = FixedPart({
                    partId: fixedPartIds[i],
                    z: catalogFixedParts[i].z,
                    metadataURI: catalogFixedParts[i].metadataURI
                });
                unchecked {
                    ++i;
                }
            }
        }

        (slotParts, ) = _getEquippedSlotParts(
            target_,
            tokenId,
            assetId,
            catalogAddress,
            slotPartIds
        );
    }

    /** @notice Used to get the child's assets and slot parts pairs, identifying parts the said assets can be equipped
     *  into, for all of parent's assets.
     * @dev Reverts if child token is not owned by an NFT.
     * @dev The full `EquippableData` struct looks like this:
     *  [
     *      slotPartId,
     *      childAssetId,
     *      parentAssetId,
     *      priority,
     *      parentCatalogAddress,
     *      isEquipped,
     *      partMetadata
     *  ]
     * @param targetChild Address of the smart contract of the given token
     * @param childId ID of the child token whose assets will be matched against parent's slot parts
     * @param onlyEquipped Boolean value signifying whether to only return the assets that are currently equipped (`true`) or to include the non-equipped ones as well (`false`)
     * @return childIndex Index of the child in the parent's list of active children
     * @return equippableData An array of `EquippableData` structs containing info about the equippable child assets and their corresponding slot parts
     */
    function getAllEquippableSlotsFromParent(
        address targetChild,
        uint256 childId,
        bool onlyEquipped
    )
        public
        view
        returns (uint256 childIndex, EquippableData[] memory equippableData)
    {
        (address parentAddress, uint256 parentId) = getParent(
            targetChild,
            childId
        );
        uint64[] memory parentAssets = IERC5773(parentAddress).getActiveAssets(
            parentId
        );
        uint256 totalParentAssets = parentAssets.length;

        uint256 totalChildAssets = IERC5773(targetChild)
            .getActiveAssets(childId)
            .length;
        uint256 totalMatchesForAll = 0;

        // This is the most valid asset combinations that can be made. When we know the real total we'll recreate it
        EquippableData[] memory allTempAssetsWithSlots = new EquippableData[](
            totalParentAssets * totalChildAssets
        );

        // Here we store temporarly the matches for each parent asset.
        EquippableData[] memory assetsWithSlotsForParentAsset;

        for (uint256 i; i < totalParentAssets; ) {
            assetsWithSlotsForParentAsset = _getEquippableSlotsFromParent(
                targetChild,
                childId,
                parentAddress,
                parentId,
                parentAssets[0]
            );
            uint totalMatchesForParentAsset = assetsWithSlotsForParentAsset
                .length;

            // We move them to the temporary array of all matches. Optionally filtering for onlyEquipped
            for (uint256 j; j < totalMatchesForParentAsset; ) {
                if (
                    !onlyEquipped || assetsWithSlotsForParentAsset[j].isEquipped
                ) {
                    allTempAssetsWithSlots[
                        totalMatchesForAll
                    ] = assetsWithSlotsForParentAsset[j];
                    unchecked {
                        ++totalMatchesForAll;
                    }
                }
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }

        equippableData = new EquippableData[](totalMatchesForAll);
        for (uint256 i; i < totalMatchesForAll; ) {
            equippableData[i] = allTempAssetsWithSlots[i];
            unchecked {
                ++i;
            }
        }

        childIndex = getChildIndex(
            parentAddress,
            parentId,
            targetChild,
            childId
        );
    }

    /**
     * @notice Used to get the child's assets and slot parts pairs, identifying parts the said assets can be equipped
     *  into, for a specific parent asset.
     * @dev Reverts if child token is not owned by an NFT.
     * @dev The full `EquippableData` struct looks like this:
     *  [
     *      slotPartId,
     *      childAssetId,
     *      parentAssetId,
     *      priority,
     *      parentCatalogAddress,
     *      isEquipped,
     *      partMetadata,
     *      childAssetMetadata,
     *      parentAssetMetadata
     *  ]
     * @param targetChild Address of the smart contract of the given token
     * @param childId ID of the child token whose assets will be matched against parent's slot parts
     * @param parentAssetId ID of the target parent asset to use to equip the child
     * @return childIndex Index of the child in the parent's list of active children
     * @return equippableData An array of `EquippableData` structs containing info about the equippable child assets and
     *  their corresponding slot parts
     */
    function getEquippableSlotsFromParent(
        address targetChild,
        uint256 childId,
        uint64 parentAssetId
    )
        public
        view
        returns (uint256 childIndex, EquippableData[] memory equippableData)
    {
        (address parentAddress, uint256 parentId) = getParent(
            targetChild,
            childId
        );
        childIndex = getChildIndex(
            parentAddress,
            parentId,
            targetChild,
            childId
        );

        equippableData = _getEquippableSlotsFromParent(
            targetChild,
            childId,
            parentAddress,
            parentId,
            parentAssetId
        );
    }

    /**
     * @notice Used to get the child's assets and slot parts pairs, identifying parts the said assets can be equipped
     *  into, for a specific parent asset while the child is in pending array.
     * @dev Reverts if child token is not owned by an NFT.
     * @dev The full `EquippableData` struct looks like this:
     *  [
     *      slotPartId,
     *      childAssetId,
     *      parentAssetId,
     *      priority,
     *      parentCatalogAddress,
     *      isEquipped,
     *      partMetadata,
     *      childAssetMetadata,
     *      parentAssetMetadata
     *  ]
     * @param targetChild Address of the smart contract of the given token
     * @param childId ID of the child token whose assets will be matched against parent's slot parts
     * @param parentAssetId ID of the target parent asset to use to equip the child
     * @return childIndex Index of the child in the parent's list of pending children
     * @return equippableData An array of `EquippableData` structs containing info about the equippable child assets and
     *  their corresponding slot parts
     */
    function getEquippableSlotsFromParentForPendingChild(
        address targetChild,
        uint256 childId,
        uint64 parentAssetId
    )
        public
        view
        returns (uint256 childIndex, EquippableData[] memory equippableData)
    {
        (address parentAddress, uint256 parentId) = getParent(
            targetChild,
            childId
        );
        childIndex = getPendingChildIndex(
            parentAddress,
            parentId,
            targetChild,
            childId
        );

        equippableData = _getEquippableSlotsFromParent(
            targetChild,
            childId,
            parentAddress,
            parentId,
            parentAssetId
        );
    }

    /**
     * @notice Used to get information about the current children equipped into a specific parent and asset.
     * @dev The full `IERC6220.Equipment` struct looks like this:
     *  [
     *       assetId
     *       childAssetId
     *       childId
     *       childEquippableAddress
     *  ]
     * @param parentAddress Address of the parent token's smart contract
     * @param parentId ID of the parent token
     * @param parentAssetId ID of the target parent asset to use to equip the child
     * @return equippedChildren An array of `IERC6220.Equipment` structs containing the info
     *  about the equipped children
     */
    function equippedChildrenOf(
        address parentAddress,
        uint256 parentId,
        uint64 parentAssetId
    ) public view returns (IERC6220.Equipment[] memory equippedChildren) {
        (
            uint64[] memory slotPartIds,
            address parentAssetCatalog
        ) = getSlotPartsAndCatalog(parentAddress, parentId, parentAssetId);
        IERC6220 target_ = IERC6220(parentAddress);
        (
            EquippedSlotPart[] memory tmpSlotParts,
            uint256 totalEquipped
        ) = _getEquippedSlotParts(
                target_,
                parentId,
                parentAssetId,
                parentAssetCatalog,
                slotPartIds
            );

        uint256 totalSlots = slotPartIds.length;
        uint256 finalIndex;
        equippedChildren = new IERC6220.Equipment[](totalEquipped);
        for (uint256 i; i < totalSlots; ) {
            if (tmpSlotParts[i].childId != 0) {
                equippedChildren[finalIndex] = IERC6220.Equipment({
                    assetId: parentAssetId,
                    childAssetId: tmpSlotParts[i].childAssetId,
                    childId: tmpSlotParts[i].childId,
                    childEquippableAddress: tmpSlotParts[i].childAddress
                });
                unchecked {
                    ++finalIndex;
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Used to get the child's assets and slot parts pairs, identifying parts the said assets can be equipped into.
     * @dev Reverts if child token is not owned by an NFT.
     * @dev The full `EquippableData` struct looks like this:
     *  [
     *       slotPartId
     *       childAssetId
     *       parentAssetId
     *       priority
     *       parentCatalogAddress
     *       isEquipped
     *       partMetadata,
     *       childAssetMetadata,
     *       parentAssetMetadata
     *  ]
     * @param childAddress Address of the smart contract of the given token
     * @param childId ID of the child token whose assets will be matched against parent's slot parts
     * @param parentAddress Address of the parent token's smart contract
     * @param parentId ID of the parent token
     * @param parentAssetId ID of the target parent asset to use to equip the child
     * @return equippableData An array of `EquippableData` structs containing info about the equippable child assets and
     *  their corresponding slot parts
     */
    function _getEquippableSlotsFromParent(
        address childAddress,
        uint256 childId,
        address parentAddress,
        uint256 parentId,
        uint64 parentAssetId
    ) private view returns (EquippableData[] memory equippableData) {
        (
            uint64[] memory parentSlotPartIds,
            address parentAssetCatalog
        ) = getSlotPartsAndCatalog(parentAddress, parentId, parentAssetId);

        (
            EquippableData[] memory tempAssetsWithSlots,
            uint256 totalMatches
        ) = _matchAllAssetsWithSlots(
                IERC6220(childAddress),
                childId,
                parentSlotPartIds,
                parentAddress,
                parentAssetCatalog
            );
        // Finally, we copy the matches into the final array which has the right lenght according to results
        equippableData = new EquippableData[](totalMatches);
        for (uint256 i; i < totalMatches; ) {
            equippableData[i] = tempAssetsWithSlots[i];
            // Ideally we would check this directly in the _matchAllAssetsWithSlots function, but we'd get stack too deep error
            // Since that function uses the limit of variables already
            equippableData[i].isEquipped = isAssetEquipped(
                parentAddress,
                parentId,
                parentAssetCatalog,
                childAddress,
                childId,
                tempAssetsWithSlots[i].childAssetId,
                tempAssetsWithSlots[i].slotPartId
            );
            equippableData[i].partMetadata = IRMRKCatalog(parentAssetCatalog)
                .getPart(tempAssetsWithSlots[i].slotPartId)
                .metadataURI;
            equippableData[i].parentAssetId = parentAssetId;
            equippableData[i].parentCatalogAddress = parentAssetCatalog;
            equippableData[i].childAssetMetadata = IERC5773(childAddress)
                .getAssetMetadata(childId, tempAssetsWithSlots[i].childAssetId);
            equippableData[i].parentAssetMetadata = IERC5773(parentAddress)
                .getAssetMetadata(parentId, parentAssetId);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Used to retrieve the equippable data of the specified token's asset with the highest priority.
     * @param target Address of the collection smart contract of the specified token
     * @param tokenId ID of the token for which to retrieve the equippable data of the asset with the highest priority
     * @return topAsset `ExtendedEquippableActiveAsset` struct with the equippable data containing the asset with the
     *  highest priority
     */
    function getTopAssetAndEquippableDataForToken(
        address target,
        uint256 tokenId
    ) public view returns (ExtendedEquippableActiveAsset memory topAsset) {
        (uint64 topAssetId, uint64 topPriority) = getAssetIdWithTopPriority(
            target,
            tokenId
        );
        (
            string memory metadataURI,
            uint64 equippableGroupId,
            address catalogAddress,
            uint64[] memory partIds
        ) = IERC6220(target).getAssetAndEquippableData(tokenId, topAssetId);
        topAsset = ExtendedEquippableActiveAsset({
            id: topAssetId,
            equippableGroupId: equippableGroupId,
            priority: topPriority,
            catalogAddress: catalogAddress,
            metadata: metadataURI,
            partIds: partIds
        });
    }

    /**
     * @notice Matches all child's assets with the corresponding slot parts of the parent, if they apply.
     * @dev The full `EquippableData` struct looks like this:
     *  [
     *       slotPartId
     *       childAssetId
     *       parentAssetId
     *       priority
     *       parentCatalogAddress
     *       isEquipped
     *       partMetadata
     *  ]
     * @dev The size of the returning array is equal to the total of available parent slots, even if there's not a match
     *  for each one.
     * @dev The valid matches are located at the beginning of the array, and the rest of the slots are filled with empty
     *  structs. Use totalMatches to know how many valid matches there are.
     * @dev Some data from the returned structs is not filled due to stack to deep limitation: parentAssetId,
     *  parentCatalogAddress, isEquipped and partMetadata.
     * @param childContract IERC6220 instance of the child smart contract
     * @param childId ID of the child token whose assets will be matched against parent's slot parts
     * @param parentSlotPartIds Array of slot part IDs of the parent token's asset
     * @param parentAddress Address of the parent smart contract
     * @param parentAssetCatalog Address of the parent asset's catalog
     * @return allAssetsWithSlots An array of `EquippableData` structs containing info about the equippable child assets
     *  and their corresponding slot parts
     * @return totalMatches Total of valid matches found
     */
    function _matchAllAssetsWithSlots(
        IERC6220 childContract,
        uint256 childId,
        uint64[] memory parentSlotPartIds,
        address parentAddress,
        address parentAssetCatalog
    )
        private
        view
        returns (
            EquippableData[] memory allAssetsWithSlots,
            uint256 totalMatches
        )
    {
        uint64[] memory childAssets = childContract.getActiveAssets(childId);
        uint64[] memory priorities = childContract.getActiveAssetPriorities(
            childId
        );

        uint256 totalChildAssets = childAssets.length;

        // There can be at most min(totalChildAssets, totalParentSlots) resulting matches, we just pick one of them.
        allAssetsWithSlots = new EquippableData[](totalChildAssets);

        for (uint256 i; i < totalChildAssets; ) {
            (, , address catalogAddress, ) = childContract
                .getAssetAndEquippableData(childId, childAssets[i]);
            for (uint256 j; j < parentSlotPartIds.length; ) {
                if (
                    catalogAddress == parentAssetCatalog &&
                    childContract.canTokenBeEquippedWithAssetIntoSlot(
                        parentAddress,
                        childId,
                        childAssets[i],
                        parentSlotPartIds[j]
                    )
                ) {
                    allAssetsWithSlots[totalMatches].childAssetId = childAssets[
                        i
                    ];
                    allAssetsWithSlots[totalMatches]
                        .slotPartId = parentSlotPartIds[j];
                    allAssetsWithSlots[totalMatches].priority = priorities[i];

                    // These will be calculated later, due to too many variables in the stack at this point:
                    // - parentAssetId
                    // - parentCatalogAddress
                    // - isEquipped
                    // - partMetadata
                    unchecked {
                        ++totalMatches;
                    }
                }
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Used to verify whether a given child asset is equipped into a given parent slot.
     * @param parentAddress Address of the collection smart contract of the parent token
     * @param parentId ID of the parent token
     * @param parentAssetCatalog Address of the catalog the parent asset belongs to
     * @param childAddress Address of the collection smart contract of the child token
     * @param childId ID of the child token
     * @param childAssetId ID of the child asset
     * @param slotPartId ID of the slot part
     * @return isEquipped Boolean value signifying whether the child asset is equipped into the parent slot or not
     */
    function isAssetEquipped(
        address parentAddress,
        uint256 parentId,
        address parentAssetCatalog,
        address childAddress,
        uint256 childId,
        uint64 childAssetId,
        uint64 slotPartId
    ) public view returns (bool isEquipped) {
        IERC6220.Equipment memory equipment = IERC6220(parentAddress)
            .getEquipment(parentId, parentAssetCatalog, slotPartId);
        isEquipped =
            equipment.childEquippableAddress == childAddress &&
            equipment.childId == childId &&
            equipment.childAssetId == childAssetId;
    }

    /**
     * @notice Used to retrieve the parent address and its slot part IDs for a given target child, and the catalog of the parent asset.
     * @param tokenAddress Address of the collection smart contract of parent token
     * @param tokenId ID of the parent token
     * @param assetId ID of the parent asset from which to get the slot parts
     * @return parentSlotPartIds Array of slot part IDs of the parent token's asset
     * @return catalogAddress Address of the catalog the parent asset belongs to
     */
    function getSlotPartsAndCatalog(
        address tokenAddress,
        uint256 tokenId,
        uint64 assetId
    )
        public
        view
        returns (uint64[] memory parentSlotPartIds, address catalogAddress)
    {
        uint64[] memory parentPartIds;
        (, , catalogAddress, parentPartIds) = IERC6220(tokenAddress)
            .getAssetAndEquippableData(tokenId, assetId);
        if (catalogAddress == address(0)) revert RMRKNotComposableAsset();

        (parentSlotPartIds, ) = splitSlotAndFixedParts(
            parentPartIds,
            catalogAddress
        );
    }

    /**
     * @notice Used to retrieve the equipped slot parts.
     * @dev The full `EquippedSlotPart` struct looks like this:
     *  [
     *      partId,
     *      childAssetId,
     *      z,
     *      childAddress,
     *      childId,
     *      childAssetMetadata,
     *      partMetadata
     *  ]
     * @param target_ An address of the `IERC6220` smart contract to retrieve the equipped slot parts from.
     * @param tokenId ID of the token for which to retrieve the equipped slot parts
     * @param assetId ID of the asset on the token to retrieve the equipped slot parts
     * @param catalogAddress The address of the catalog to which the given asset belongs to
     * @param slotPartIds An array of slot part IDs in the asset for which to retrieve the equipped slot parts
     * @return slotParts An array of `EquippedSlotPart` structs representing the equipped slot parts
     * @return totalEquipped Total of slot parts with some asset equipped.
     */
    function _getEquippedSlotParts(
        IERC6220 target_,
        uint256 tokenId,
        uint64 assetId,
        address catalogAddress,
        uint64[] memory slotPartIds
    )
        private
        view
        returns (EquippedSlotPart[] memory slotParts, uint256 totalEquipped)
    {
        slotParts = new EquippedSlotPart[](slotPartIds.length);
        uint256 len = slotPartIds.length;

        if (len != 0) {
            string memory metadata;
            IRMRKCatalog.Part[] memory catalogSlotParts = IRMRKCatalog(
                catalogAddress
            ).getParts(slotPartIds);
            for (uint256 i; i < len; ) {
                IERC6220.Equipment memory equipment = target_.getEquipment(
                    tokenId,
                    catalogAddress,
                    slotPartIds[i]
                );
                if (equipment.assetId == assetId) {
                    metadata = IERC6220(equipment.childEquippableAddress)
                        .getAssetMetadata(
                            equipment.childId,
                            equipment.childAssetId
                        );
                    slotParts[i] = EquippedSlotPart({
                        partId: slotPartIds[i],
                        childAssetId: equipment.childAssetId,
                        z: catalogSlotParts[i].z,
                        childId: equipment.childId,
                        childAddress: equipment.childEquippableAddress,
                        childAssetMetadata: metadata,
                        partMetadata: catalogSlotParts[i].metadataURI
                    });
                    unchecked {
                        ++totalEquipped;
                    }
                } else {
                    slotParts[i].partId = slotPartIds[i];
                    slotParts[i].z = catalogSlotParts[i].z;
                    slotParts[i].partMetadata = catalogSlotParts[i].metadataURI;
                }
                unchecked {
                    ++i;
                }
            }
        }
    }

    /**
     * @notice Used to split slot and fixed parts.
     * @param allPartIds[] An array of `Part` IDs containing both, `Slot` and `Fixed` parts
     * @param catalogAddress An address of the catalog to which the given `Part`s belong to
     * @return slotPartIds An array of IDs of the `Slot` parts included in the `allPartIds`
     * @return fixedPartIds An array of IDs of the `Fixed` parts included in the `allPartIds`
     */
    function splitSlotAndFixedParts(
        uint64[] memory allPartIds,
        address catalogAddress
    )
        public
        view
        returns (uint64[] memory slotPartIds, uint64[] memory fixedPartIds)
    {
        IRMRKCatalog.Part[] memory allParts = IRMRKCatalog(catalogAddress)
            .getParts(allPartIds);
        uint256 numFixedParts;
        uint256 numSlotParts;

        uint256 numParts = allPartIds.length;
        // This for loop is just to discover the right size of the split arrays, since we can't create them dynamically
        for (uint256 i; i < numParts; ) {
            if (allParts[i].itemType == IRMRKCatalog.ItemType.Fixed)
                numFixedParts += 1;
                // We could just take the numParts - numFixedParts, but it doesn't hurt to double check it's not an uninitialized part:
            else if (allParts[i].itemType == IRMRKCatalog.ItemType.Slot)
                numSlotParts += 1;
            unchecked {
                ++i;
            }
        }

        slotPartIds = new uint64[](numSlotParts);
        fixedPartIds = new uint64[](numFixedParts);
        uint256 slotPartsIndex;
        uint256 fixedPartsIndex;

        // This for loop is to actually fill the split arrays
        for (uint256 i; i < numParts; ) {
            if (allParts[i].itemType == IRMRKCatalog.ItemType.Fixed) {
                fixedPartIds[fixedPartsIndex] = allPartIds[i];
                fixedPartsIndex += 1;
            } else if (allParts[i].itemType == IRMRKCatalog.ItemType.Slot) {
                slotPartIds[slotPartsIndex] = allPartIds[i];
                slotPartsIndex += 1;
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev The full `ChildWithTopAssetMetadata` struct looks like this:
     *  [
     *      contractAddress,
     *      tokenId,
     *      metadata
     *  ]
     * @param parentAddress Address of the collection smart contract of the parent token
     * @param parentId ID of the parent token
     * @return An array of `ChildWithTopAssetMetadata` structs representing the children with their top asset metadata
     */
    function getChildrenWithTopMetadata(
        address parentAddress,
        uint256 parentId
    ) public view returns (ChildWithTopAssetMetadata[] memory) {
        IERC6059.Child[] memory children = IERC6059(parentAddress).childrenOf(
            parentId
        );
        (parentId);
        uint256 len = children.length;
        ChildWithTopAssetMetadata[]
            memory childrenWithMetadata = new ChildWithTopAssetMetadata[](len);

        for (uint256 i; i < len; ) {
            string memory meta = getTopAssetMetaForToken(
                children[i].contractAddress,
                children[i].tokenId
            );
            childrenWithMetadata[i] = ChildWithTopAssetMetadata(
                children[i].contractAddress,
                children[i].tokenId,
                meta
            );
            unchecked {
                ++i;
            }
        }
        return childrenWithMetadata;
    }
}