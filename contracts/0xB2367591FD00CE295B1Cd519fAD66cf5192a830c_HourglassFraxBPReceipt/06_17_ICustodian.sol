// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface ICustodian {
    function assetIdToMaturityToVault(
        uint256 assetId, 
        uint256 maturity
    ) external view returns (address);
    
    function migrateToMaturedVault(
        uint256 assetId, 
        address vault, 
        uint256 maturity
    ) external returns (uint256 withdrawnAmount);

    function vaultMatured(address depositVault) external view returns (bool);
}