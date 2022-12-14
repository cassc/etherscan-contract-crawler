// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface IbridgeMigrator {
    function isDirectSwap(address assetAddress, uint256 chainID)
        external
        returns (bool);

    function registerNativeMigration(
        address assetAddress,
        uint256[2] memory limits,
        uint256 collectedFees,
        bool ownedRail,
        address manager,
        address feeRemitance,
        uint256[3] memory balances,
        bool active,
        uint256[] memory supportedChains
    ) external payable;

    function registerForiegnMigration(
        address foriegnAddress,
        uint256 chainID,
        uint256 minAmount,
        uint256 maxAmount,
        bool ownedRail,
        address manager,
        address feeAddress,
        uint256 _collectedFees,
        bool directSwap,
        address wrappedAddress
    ) external;
}