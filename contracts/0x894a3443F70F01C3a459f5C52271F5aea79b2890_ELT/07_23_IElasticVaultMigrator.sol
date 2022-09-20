// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IElasticVaultMigrator {
    function migrate(
        address currentAsset,
        address newAsset,
        uint256 amount
    ) external;
}