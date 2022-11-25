// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {Vault} from "../libraries/Vault.sol";

interface IRibbonEarnVault {
    function vaultParams() external view returns (Vault.VaultParams memory);

    function vaultState() external view returns (Vault.VaultState memory);

    function pricePerShare() external view returns (uint256);

    function roundPricePerShare(uint256) external view returns (uint256);

    function depositFor(uint256 amount, address creditor) external;

    function initiateWithdraw(uint256 numShares) external;

    function completeWithdraw() external;

    function maxRedeem() external;

    function symbol() external view returns (string calldata);

    function depositYieldTokenFor(uint256 amount, address creditor) external;
}