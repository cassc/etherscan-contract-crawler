// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { Vault } from "../libraries/Vault.sol";

interface IHashnoteOptionsVault {
    function whitelist() external view returns (address);

    function vaultParams() external view returns (Vault.VaultParams memory);

    function vaultState() external view returns (Vault.VaultState memory);

    function optionState() external view returns (Vault.OptionState memory);

    function auctionId() external view returns (uint256);

    function depositFor(uint256 amount, address creditor) external;

    function requestWithdraw(uint256 numShares) external;

    function instruments() external view returns (Vault.Instrument[] memory);

    function getCollaterals() external view returns (Vault.Collateral[] memory);
}