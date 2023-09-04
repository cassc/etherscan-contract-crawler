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
    event PausedAsset(address token, address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event UnpausedAsset(address token, address account);

    // We use the asset's underlying token as the key to check whether an asset is paused.
    // A pool will never have two assets with the same underlying token.
    mapping(address => bool) private _pausedAssets;

    error WOMBAT_ASSET_ALREADY_PAUSED();
    error WOMBAT_ASSET_NOT_PAUSED();

    /**
     * @dev Function to return if the asset is paused.
     * The return value is only useful when true.
     * When the return value is false, the asset can be either not paused or not exist.
     */
    function isPaused(address token) public view returns (bool) {
        return _pausedAssets[token];
    }

    /**
     * @dev Function to make a function callable only when the asset is not paused.
     *
     * Requirements:
     *
     * - The asset must not be paused.
     */
    function requireAssetNotPaused(address token) internal view {
        if (_pausedAssets[token]) revert WOMBAT_ASSET_ALREADY_PAUSED();
    }

    /**
     * @dev Function to make a function callable only when the asset is paused.
     *
     * Requirements:
     *
     * - The asset must be paused.
     */
    function requireAssetPaused(address token) internal view {
        if (!_pausedAssets[token]) revert WOMBAT_ASSET_NOT_PAUSED();
    }

    /**
     * @dev Triggers paused state.
     *
     * Requirements:
     *
     * - The asset must not be paused.
     */
    function _pauseAsset(address token) internal {
        requireAssetNotPaused(token);
        _pausedAssets[token] = true;
        emit PausedAsset(token, msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The asset must be paused.
     */
    function _unpauseAsset(address token) internal {
        requireAssetPaused(token);
        _pausedAssets[token] = false;
        emit UnpausedAsset(token, msg.sender);
    }
}