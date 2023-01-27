// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICaskDCAManager {

    function registerDCA(bytes32 _dcaId) external;

    /** @dev Emitted when manager parameters are changed. */
    event SetParameters();

    /** @dev Emitted when an assetSpec is blacklisted. */
    event BlacklistAssetSpec(bytes32 indexed assetSpec);

    /** @dev Emitted when an assetSpec is unblacklisted. */
    event UnblacklistAssetSpec(bytes32 indexed assetSpec);

    /** @dev Emitted the feeDistributor is changed. */
    event SetFeeDistributor(address feeDistributor);
}