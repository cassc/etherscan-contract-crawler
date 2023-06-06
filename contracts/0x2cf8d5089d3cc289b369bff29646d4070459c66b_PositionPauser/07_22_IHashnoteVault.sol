// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IMarginEnginePhysical} from "./IMarginEngine.sol";
import {IVaultShare} from "./IVaultShare.sol";

import "../config/types.sol";

interface IHashnoteVault {
    function share() external view returns (IVaultShare);

    function roundExpiry(uint256 round) external view returns (uint256);

    function whitelist() external view returns (address);

    function vaultState() external view returns (VaultState memory);

    function depositFor(uint256 amount, address creditor) external;

    function requestWithdraw(uint256 numShares) external;

    function getCollaterals() external view returns (Collateral[] memory);

    function depositReceipts(address depositor) external view returns (DepositReceipt memory);

    function redeemFor(address depositor, uint256 numShares, bool isMax) external;

    function managementFee() external view returns (uint256);

    function feeRecipient() external view returns (address);
}

interface IHashnotePhysicalOptionsVault is IHashnoteVault {
    function marginEngine() external view returns (IMarginEnginePhysical);

    function burnSharesFor(address depositor, uint256 sharesToWithdraw) external;
}