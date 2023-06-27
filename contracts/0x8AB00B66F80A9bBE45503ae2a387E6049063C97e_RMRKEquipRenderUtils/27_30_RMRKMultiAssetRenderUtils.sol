// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

import "../multiasset/IERC5773.sol";
import "../library/RMRKErrors.sol";

/**
 * @title RMRKMultiAssetRenderUtils
 * @author RMRK team
 */
contract RMRKMultiAssetRenderUtils {
    uint64 private constant _LOWEST_POSSIBLE_PRIORITY = 2 ** 64 - 1;

    /**
     * @notice The structure used to display information about an active asset.
     * @return id ID of the asset
     * @return priority The priority assigned to the asset
     * @return metadata The metadata URI of the asset
     */
    struct ExtendedActiveAsset {
        uint64 id;
        uint64 priority;
        string metadata;
    }

    /**
     * @notice The structure used to display information about a pending asset.
     * @return id ID of the asset
     * @return acceptRejectIndex An index to use in order to accept or reject the given asset
     * @return replacesAssetWithId ID of the asset that would be replaced if this asset gets accepted
     * @return metadata The metadata URI of the asset
     */
    struct PendingAsset {
        uint64 id;
        uint128 acceptRejectIndex;
        uint64 replacesAssetWithId;
        string metadata;
    }

    /**
     * @notice Used to get the active assets of the given token.
     * @dev The full `ExtendedActiveAsset` looks like this:
     *  [
     *      id,
     *      priority,
     *      metadata
     *  ]
     * @param target Address of the smart contract of the given token
     * @param tokenId ID of the token to retrieve the active assets for
     * @return An array of ActiveAssets present on the given token
     */
    function getExtendedActiveAssets(
        address target,
        uint256 tokenId
    ) public view virtual returns (ExtendedActiveAsset[] memory) {
        IERC5773 target_ = IERC5773(target);

        uint64[] memory assets = target_.getActiveAssets(tokenId);
        uint64[] memory priorities = target_.getActiveAssetPriorities(tokenId);
        uint256 len = assets.length;
        if (len == uint256(0)) {
            revert RMRKTokenHasNoAssets();
        }

        ExtendedActiveAsset[] memory activeAssets = new ExtendedActiveAsset[](
            len
        );
        string memory metadata;
        for (uint256 i; i < len; ) {
            metadata = target_.getAssetMetadata(tokenId, assets[i]);
            activeAssets[i] = ExtendedActiveAsset({
                id: assets[i],
                priority: priorities[i],
                metadata: metadata
            });
            unchecked {
                ++i;
            }
        }
        return activeAssets;
    }

    /**
     * @notice Used to get the pending assets of the given token.
     * @dev The full `PendingAsset` looks like this:
     *  [
     *      id,
     *      acceptRejectIndex,
     *      replacesAssetWithId,
     *      metadata
     *  ]
     * @param target Address of the smart contract of the given token
     * @param tokenId ID of the token to retrieve the pending assets for
     * @return An array of PendingAssets present on the given token
     */
    function getPendingAssets(
        address target,
        uint256 tokenId
    ) public view virtual returns (PendingAsset[] memory) {
        IERC5773 target_ = IERC5773(target);

        uint64[] memory assets = target_.getPendingAssets(tokenId);
        uint256 len = assets.length;
        if (len == uint256(0)) {
            revert RMRKTokenHasNoAssets();
        }

        PendingAsset[] memory pendingAssets = new PendingAsset[](len);
        string memory metadata;
        uint64 replacesAssetWithId;
        for (uint256 i; i < len; ) {
            metadata = target_.getAssetMetadata(tokenId, assets[i]);
            replacesAssetWithId = target_.getAssetReplacements(
                tokenId,
                assets[i]
            );
            pendingAssets[i] = PendingAsset({
                id: assets[i],
                acceptRejectIndex: uint128(i),
                replacesAssetWithId: replacesAssetWithId,
                metadata: metadata
            });
            unchecked {
                ++i;
            }
        }
        return pendingAssets;
    }

    /**
     * @notice Used to retrieve the metadata URI of specified assets in the specified token.
     * @dev Requirements:
     *
     *  - `assetIds` must exist.
     * @param target Address of the smart contract of the given token
     * @param tokenId ID of the token to retrieve the specified assets for
     * @param assetIds[] An array of asset IDs for which to retrieve the metadata URIs
     * @return An array of metadata URIs belonging to specified assets
     */
    function getAssetsById(
        address target,
        uint256 tokenId,
        uint64[] calldata assetIds
    ) public view virtual returns (string[] memory) {
        IERC5773 target_ = IERC5773(target);
        uint256 len = assetIds.length;
        string[] memory assets = new string[](len);
        for (uint256 i; i < len; ) {
            assets[i] = target_.getAssetMetadata(tokenId, assetIds[i]);
            unchecked {
                ++i;
            }
        }
        return assets;
    }

    /**
     * @notice Used to retrieve the metadata URI of the specified token's asset with the highest priority.
     * @param target Address of the smart contract of the given token
     * @param tokenId ID of the token for which to retrieve the metadata URI of the asset with the highest priority
     * @return The metadata URI of the asset with the highest priority
     */
    function getTopAssetMetaForToken(
        address target,
        uint256 tokenId
    ) public view returns (string memory) {
        (uint64 maxPriorityAssetId, ) = getAssetIdWithTopPriority(
            target,
            tokenId
        );
        return IERC5773(target).getAssetMetadata(tokenId, maxPriorityAssetId);
    }

    /**
     * @notice Used to retrieve the metadata URI of the specified token's asset with the highest priority for each of the given tokens.
     * @param target Address of the smart contract of the tokens
     * @param tokenIds IDs of the tokens for which to retrieve the metadata URIs
     * @return metadata An array of strings with the top asset metadata for each of the given tokens, in the same order as the tokens passed in the `tokenIds` input array
     */
    function getTopAssetMetadataForTokens(
        address target,
        uint256[] memory tokenIds
    ) public view returns (string[] memory metadata) {
        uint256 len = tokenIds.length;
        metadata = new string[](len);

        for (uint256 i; i < len; ) {
            metadata[i] = getTopAssetMetaForToken(target, tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Used to retrieve the ID of the specified token's asset with the highest priority.
     * @param target Address of the smart contract of the given token
     * @param tokenId ID of the token for which to retrieve the ID of the asset with the highest priority
     * @return The ID of the asset with the highest priority
     * @return The priority value of the asset with the highest priority
     */
    function getAssetIdWithTopPriority(
        address target,
        uint256 tokenId
    ) public view returns (uint64, uint64) {
        IERC5773 target_ = IERC5773(target);
        uint64[] memory priorities = target_.getActiveAssetPriorities(tokenId);
        uint64[] memory assets = target_.getActiveAssets(tokenId);
        uint256 len = priorities.length;
        if (len == uint256(0)) {
            revert RMRKTokenHasNoAssets();
        }

        uint64 maxPriority = _LOWEST_POSSIBLE_PRIORITY;
        uint64 maxPriorityAssetId;
        for (uint64 i; i < len; ) {
            uint64 currentPrio = priorities[i];
            if (currentPrio < maxPriority) {
                maxPriority = currentPrio;
                maxPriorityAssetId = assets[i];
            }
            unchecked {
                ++i;
            }
        }
        return (maxPriorityAssetId, maxPriority);
    }

    /**
     * @notice Used to retrieve ID, priority value and metadata URI of the asset with the highest priority that is
     *  present on a specified token.
     * @param target Collection smart contract of the token for which to retireve the top asset
     * @param tokenId ID of the token for which to retrieve the top asset
     * @return topAssetId ID of the asset with the highest priority
     * @return topAssetPriority Priotity value of the asset with the highest priority
     * @return topAssetMetadata Metadata URI of the asset with the highest priority
     */
    function getTopAsset(
        address target,
        uint256 tokenId
    )
        public
        view
        returns (
            uint64 topAssetId,
            uint64 topAssetPriority,
            string memory topAssetMetadata
        )
    {
        (topAssetId, topAssetPriority) = getAssetIdWithTopPriority(
            target,
            tokenId
        );
        topAssetMetadata = IERC5773(target).getAssetMetadata(
            tokenId,
            topAssetId
        );
    }
}