// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.12;

interface IVaultWrapper {
    
    error NoAvailableShares();
    error NotEnoughAvailableSharesForAmount();
    error SpenderDoesNotHaveApprovalToBurnShares();
    error NotEnoughAvailableAssetsForAmount();
    error InvalidMigrationTarget();
    error MinimumDepositNotMet();
    error NonZeroArgumentExpected();

    function vault() external view returns (address);

    function vaultTotalSupply() external view returns (uint256);
}