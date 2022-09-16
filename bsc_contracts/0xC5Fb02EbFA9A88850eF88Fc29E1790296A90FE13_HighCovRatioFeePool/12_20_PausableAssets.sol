// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.5;

/**
 * @title PausableAssets
 * @notice Handles assets pause and unpause of Wombat protocol.
 * @dev Allows pausing and unpausing of deposit and swap operations
 */
contract PausableAssets {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event PausedAsset(address asset, address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event UnpausedAsset(address asset, address account);

    mapping(address => bool) private _pausedAssets;

    error WOMBAT_ASSET_ALREADY_PAUSED();
    error WOMBAT_ASSET_NOT_PAUSED();

    /**
     * @dev Function to make a function callable only when the asset is not paused.
     *
     * Requirements:
     *
     * - The asset must not be paused.
     */
    function requireAssetNotPaused(address asset) internal view {
        if (_pausedAssets[asset]) revert WOMBAT_ASSET_ALREADY_PAUSED();
    }

    /**
     * @dev Function to make a function callable only when the asset is paused.
     *
     * Requirements:
     *
     * - The asset must be paused.
     */
    function requireAssetPaused(address asset) internal view {
        if (!_pausedAssets[asset]) revert WOMBAT_ASSET_NOT_PAUSED();
    }

    /**
     * @dev Triggers paused state.
     *
     * Requirements:
     *
     * - The asset must not be paused.
     */
    function _pauseAsset(address asset) internal {
        requireAssetNotPaused(asset);
        _pausedAssets[asset] = true;
        emit PausedAsset(asset, msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The asset must be paused.
     */
    function _unpauseAsset(address asset) internal {
        requireAssetPaused(asset);
        _pausedAssets[asset] = false;
        emit UnpausedAsset(asset, msg.sender);
    }
}