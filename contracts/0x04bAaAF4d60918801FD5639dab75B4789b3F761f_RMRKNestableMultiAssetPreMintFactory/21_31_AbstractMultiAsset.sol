// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

import "./IERC5773.sol";
import "../library/RMRKLib.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "../library/RMRKErrors.sol";

/**
 * @title AbstractMultiAsset
 * @author RMRK team
 * @notice Abstract Smart contract implementing most of the common logic for contracts implementing IERC5773
 */
abstract contract AbstractMultiAsset is Context, IERC5773 {
    using RMRKLib for uint64[];

    /// Mapping of uint64 Ids to asset metadata
    mapping(uint64 => string) private _assets;

    /// Mapping of tokenId to new asset, to asset to be replaced
    mapping(uint256 => mapping(uint64 => uint64)) private _assetReplacements;

    /// Mapping of tokenId to an array of active assets
    /// @dev Active recurses is unbounded, getting all would reach gas limit at around 30k items
    /// so we leave this as internal in case a custom implementation needs to implement pagination
    mapping(uint256 => uint64[]) internal _activeAssets;

    /// Mapping of tokenId to an array of pending assets
    mapping(uint256 => uint64[]) internal _pendingAssets;

    /// Mapping of tokenId to an array of priorities for active assets
    mapping(uint256 => uint64[]) internal _activeAssetPriorities;

    /// Mapping of tokenId to assetId to whether the token has this asset assigned
    mapping(uint256 => mapping(uint64 => bool)) private _tokenAssets;

    /// Mapping from owner to operator approvals for assets
    mapping(address => mapping(address => bool))
        private _operatorApprovalsForAssets;

    /**
     * @inheritdoc IERC5773
     */
    function getAssetMetadata(
        uint256 tokenId,
        uint64 assetId
    ) public view virtual returns (string memory) {
        if (!_tokenAssets[tokenId][assetId]) revert RMRKTokenDoesNotHaveAsset();
        return _assets[assetId];
    }

    /**
     * @inheritdoc IERC5773
     */
    function getActiveAssets(
        uint256 tokenId
    ) public view virtual returns (uint64[] memory) {
        return _activeAssets[tokenId];
    }

    /**
     * @inheritdoc IERC5773
     */
    function getPendingAssets(
        uint256 tokenId
    ) public view virtual returns (uint64[] memory) {
        return _pendingAssets[tokenId];
    }

    /**
     * @inheritdoc IERC5773
     */
    function getActiveAssetPriorities(
        uint256 tokenId
    ) public view virtual returns (uint64[] memory) {
        return _activeAssetPriorities[tokenId];
    }

    /**
     * @inheritdoc IERC5773
     */
    function getAssetReplacements(
        uint256 tokenId,
        uint64 newAssetId
    ) public view virtual returns (uint64) {
        return _assetReplacements[tokenId][newAssetId];
    }

    /**
     * @inheritdoc IERC5773
     */
    function isApprovedForAllForAssets(
        address owner,
        address operator
    ) public view virtual returns (bool) {
        return _operatorApprovalsForAssets[owner][operator];
    }

    /**
     * @inheritdoc IERC5773
     */
    function setApprovalForAllForAssets(
        address operator,
        bool approved
    ) public virtual {
        if (_msgSender() == operator)
            revert RMRKApprovalForAssetsToCurrentOwner();

        _operatorApprovalsForAssets[_msgSender()][operator] = approved;
        emit ApprovalForAllForAssets(_msgSender(), operator, approved);
    }

    /**
     * @notice Used to accept a pending asset.
     * @dev The call is reverted if there is no pending asset at a given index.
     * @dev Emits ***AssetAccepted*** event.
     * @param tokenId ID of the token for which to accept the pending asset
     * @param index Index of the asset in the pending array to accept
     * @param assetId ID of the asset to accept in token's pending array
     */
    function _acceptAsset(
        uint256 tokenId,
        uint256 index,
        uint64 assetId
    ) internal virtual {
        _validatePendingAssetAtIndex(tokenId, index, assetId);
        _beforeAcceptAsset(tokenId, index, assetId);

        uint64 replacesId = _assetReplacements[tokenId][assetId];
        uint256 replaceIndex;
        bool replacefound;
        if (replacesId != uint64(0))
            (replaceIndex, replacefound) = _activeAssets[tokenId].indexOf(
                replacesId
            );

        if (replacefound) {
            // We don't want to remove and then push a new asset.
            // This way we also keep the priority of the original asset
            _activeAssets[tokenId][replaceIndex] = assetId;
            delete _tokenAssets[tokenId][replacesId];
        } else {
            // We use the current size as next priority, by default priorities would be [0,1,2...]
            _activeAssetPriorities[tokenId].push(
                uint64(_activeAssets[tokenId].length)
            );
            _activeAssets[tokenId].push(assetId);
            replacesId = uint64(0);
        }
        _removePendingAsset(tokenId, index, assetId);

        emit AssetAccepted(tokenId, assetId, replacesId);
        _afterAcceptAsset(tokenId, index, assetId);
    }

    /**
     * @notice Used to reject the specified asset from the pending array.
     * @dev The call is reverted if there is no pending asset at a given index.
     * @dev Emits ***AssetRejected*** event.
     * @param tokenId ID of the token that the asset is being rejected from
     * @param index Index of the asset in the pending array to be rejected
     * @param assetId ID of the asset expected to be in the index
     */
    function _rejectAsset(
        uint256 tokenId,
        uint256 index,
        uint64 assetId
    ) internal virtual {
        _validatePendingAssetAtIndex(tokenId, index, assetId);
        _beforeRejectAsset(tokenId, index, assetId);

        _removePendingAsset(tokenId, index, assetId);
        delete _tokenAssets[tokenId][assetId];

        emit AssetRejected(tokenId, assetId);
        _afterRejectAsset(tokenId, index, assetId);
    }

    /**
     * @notice Used to validate the index on the pending assets array
     * @dev The call is reverted if the index is out of range or the asset Id is not present at the index.
     * @param tokenId ID of the token that the asset is validated from
     * @param index Index of the asset in the pending array
     * @param assetId Id of the asset expected to be in the index
     */
    function _validatePendingAssetAtIndex(
        uint256 tokenId,
        uint256 index,
        uint64 assetId
    ) private view {
        if (index >= _pendingAssets[tokenId].length)
            revert RMRKIndexOutOfRange();
        if (assetId != _pendingAssets[tokenId][index])
            revert RMRKUnexpectedAssetId();
    }

    /**
     * @notice Used to remove the asset at the index on the pending assets array
     * @param tokenId ID of the token that the asset is being removed from
     * @param index Index of the asset in the pending array
     * @param assetId Id of the asset expected to be in the index
     */
    function _removePendingAsset(
        uint256 tokenId,
        uint256 index,
        uint64 assetId
    ) private {
        _pendingAssets[tokenId].removeItemByIndex(index);
        delete _assetReplacements[tokenId][assetId];
    }

    /**
     * @notice Used to reject all of the pending assets for the given token.
     * @dev When rejecting all assets, the pending array is indiscriminately cleared.
     * @dev If the number of pending assets is greater than the value of `maxRejections`, the exectuion will be
     *  reverted.
     * @dev Emits ***AssetRejected*** event.
     * @param tokenId ID of the token to reject all of the pending assets.
     * @param maxRejections Maximum number of expected assets to reject, used to prevent from
     *  rejecting assets which arrive just before this operation.
     */
    function _rejectAllAssets(
        uint256 tokenId,
        uint256 maxRejections
    ) internal virtual {
        uint256 len = _pendingAssets[tokenId].length;
        if (len > maxRejections) revert RMRKUnexpectedNumberOfAssets();

        _beforeRejectAllAssets(tokenId);

        for (uint256 i; i < len; ) {
            uint64 assetId = _pendingAssets[tokenId][i];
            delete _assetReplacements[tokenId][assetId];
            unchecked {
                ++i;
            }
        }
        delete (_pendingAssets[tokenId]);

        emit AssetRejected(tokenId, uint64(0));
        _afterRejectAllAssets(tokenId);
    }

    /**
     * @notice Used to specify the priorities for a given token's active assets.
     * @dev If the length of the priorities array doesn't match the length of the active assets array, the execution
     *  will be reverted.
     * @dev The position of the priority value in the array corresponds the position of the asset in the active
     *  assets array it will be applied to.
     * @dev Emits ***AssetPrioritySet*** event.
     * @param tokenId ID of the token for which the priorities are being set
     * @param priorities Array of priorities for the assets
     */
    function _setPriority(
        uint256 tokenId,
        uint64[] calldata priorities
    ) internal virtual {
        uint256 length = priorities.length;
        if (length != _activeAssets[tokenId].length)
            revert RMRKBadPriorityListLength();

        _beforeSetPriority(tokenId, priorities);
        _activeAssetPriorities[tokenId] = priorities;

        emit AssetPrioritySet(tokenId);
        _afterSetPriority(tokenId, priorities);
    }

    /**
     * @notice Used to add an asset entry.
     * @dev If the specified ID is already used by another asset, the execution will be reverted.
     * @dev This internal function warrants custom access control to be implemented when used.
     * @dev Emits ***AssetSet*** event.
     * @param id ID of the asset to assign to the new asset
     * @param metadataURI Metadata URI of the asset
     */
    function _addAssetEntry(
        uint64 id,
        string memory metadataURI
    ) internal virtual {
        if (id == uint64(0)) revert RMRKIdZeroForbidden();
        if (bytes(_assets[id]).length > 0) revert RMRKAssetAlreadyExists();

        _beforeAddAsset(id, metadataURI);
        _assets[id] = metadataURI;

        emit AssetSet(id);
        _afterAddAsset(id, metadataURI);
    }

    /**
     * @notice Used to add an asset to a token.
     * @dev If the given asset is already added to the token, the execution will be reverted.
     * @dev If the asset ID is invalid, the execution will be reverted.
     * @dev If the token already has the maximum amount of pending assets (128), the execution will be
     *  reverted.
     * @dev Emits ***AssetAddedToTokens*** event.
     * @param tokenId ID of the token to add the asset to
     * @param assetId ID of the asset to add to the token
     * @param replacesAssetWithId ID of the asset to replace from the token's list of active assets
     */
    function _addAssetToToken(
        uint256 tokenId,
        uint64 assetId,
        uint64 replacesAssetWithId
    ) internal virtual {
        if (_tokenAssets[tokenId][assetId]) revert RMRKAssetAlreadyExists();

        if (bytes(_assets[assetId]).length == uint256(0))
            revert RMRKNoAssetMatchingId();

        if (_pendingAssets[tokenId].length >= 128)
            revert RMRKMaxPendingAssetsReached();

        _beforeAddAssetToToken(tokenId, assetId, replacesAssetWithId);
        _tokenAssets[tokenId][assetId] = true;
        _pendingAssets[tokenId].push(assetId);

        if (replacesAssetWithId != uint64(0)) {
            _assetReplacements[tokenId][assetId] = replacesAssetWithId;
        }

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        emit AssetAddedToTokens(tokenIds, assetId, replacesAssetWithId);
        _afterAddAssetToToken(tokenId, assetId, replacesAssetWithId);
    }

    /**
     * @notice Hook that is called before an asset is added.
     * @param id ID of the asset
     * @param metadataURI Metadata URI of the asset
     */
    function _beforeAddAsset(
        uint64 id,
        string memory metadataURI
    ) internal virtual {}

    /**
     * @notice Hook that is called after an asset is added.
     * @param id ID of the asset
     * @param metadataURI Metadata URI of the asset
     */
    function _afterAddAsset(
        uint64 id,
        string memory metadataURI
    ) internal virtual {}

    /**
     * @notice Hook that is called before adding an asset to a token's pending assets array.
     * @dev If the asset doesn't intend to replace another asset, the `replacesAssetWithId` value should be `0`.
     * @param tokenId ID of the token to which the asset is being added
     * @param assetId ID of the asset that is being added
     * @param replacesAssetWithId ID of the asset that this asset is attempting to replace
     */
    function _beforeAddAssetToToken(
        uint256 tokenId,
        uint64 assetId,
        uint64 replacesAssetWithId
    ) internal virtual {}

    /**
     * @notice Hook that is called after an asset has been added to a token's pending assets array.
     * @dev If the asset doesn't intend to replace another asset, the `replacesAssetWithId` value should be `0`.
     * @param tokenId ID of the token to which the asset is has been added
     * @param assetId ID of the asset that is has been added
     * @param replacesAssetWithId ID of the asset that this asset is attempting to replace
     */
    function _afterAddAssetToToken(
        uint256 tokenId,
        uint64 assetId,
        uint64 replacesAssetWithId
    ) internal virtual {}

    /**
     * @notice Hook that is called before an asset is accepted to a token's active assets array.
     * @param tokenId ID of the token for which the asset is being accepted
     * @param index Index of the asset in the token's pending assets array
     * @param assetId ID of the asset expected to be located at the specified `index`
     */
    function _beforeAcceptAsset(
        uint256 tokenId,
        uint256 index,
        uint64 assetId
    ) internal virtual {}

    /**
     * @notice Hook that is called after an asset is accepted to a token's active assets array.
     * @param tokenId ID of the token for which the asset has been accepted
     * @param index Index of the asset in the token's pending assets array
     * @param assetId ID of the asset expected to have been located at the specified `index`
     */
    function _afterAcceptAsset(
        uint256 tokenId,
        uint256 index,
        uint64 assetId
    ) internal virtual {}

    /**
     * @notice Hook that is called before rejecting an asset.
     * @param tokenId ID of the token from which the asset is being rejected
     * @param index Index of the asset in the token's pending assets array
     * @param assetId ID of the asset expected to be located at the specified `index`
     */
    function _beforeRejectAsset(
        uint256 tokenId,
        uint256 index,
        uint64 assetId
    ) internal virtual {}

    /**
     * @notice Hook that is called after rejecting an asset.
     * @param tokenId ID of the token from which the asset has been rejected
     * @param index Index of the asset in the token's pending assets array
     * @param assetId ID of the asset expected to have been located at the specified `index`
     */
    function _afterRejectAsset(
        uint256 tokenId,
        uint256 index,
        uint64 assetId
    ) internal virtual {}

    /**
     * @notice Hook that is called before rejecting all assets of a token.
     * @param tokenId ID of the token from which all of the assets are being rejected
     */
    function _beforeRejectAllAssets(uint256 tokenId) internal virtual {}

    /**
     * @notice Hook that is called after rejecting all assets of a token.
     * @param tokenId ID of the token from which all of the assets have been rejected
     */
    function _afterRejectAllAssets(uint256 tokenId) internal virtual {}

    /**
     * @notice Hook that is called before the priorities for token's assets is set.
     * @param tokenId ID of the token for which the asset priorities are being set
     * @param priorities[] An array of priorities for token's active resources
     */
    function _beforeSetPriority(
        uint256 tokenId,
        uint64[] calldata priorities
    ) internal virtual {}

    /**
     * @notice Hook that is called after the priorities for token's assets is set.
     * @param tokenId ID of the token for which the asset priorities have been set
     * @param priorities[] An array of priorities for token's active resources
     */
    function _afterSetPriority(
        uint256 tokenId,
        uint64[] calldata priorities
    ) internal virtual {}
}