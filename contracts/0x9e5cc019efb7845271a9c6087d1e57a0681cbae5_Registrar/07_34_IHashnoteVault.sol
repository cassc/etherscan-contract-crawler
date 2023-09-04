// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IMarginEngine} from "./IMarginEngine.sol";
import {IVaultShare} from "./IVaultShare.sol";

import "../config/types.sol";

interface IHashnoteVault {
    function share() external view returns (IVaultShare);

    function manager() external view returns (address);

    function whitelist() external view returns (address);

    function managementFee() external view returns (uint256);

    function feeRecipient() external view returns (address);

    function marginEngine() external view returns (IMarginEngine);

    function vaultState() external view returns (VaultState memory);

    function _depositReceipts(address subAccount) external view returns (DepositReceipt memory);

    function deposit(uint256 amount) external;

    function quickWithdraw(uint256 amount) external;

    function requestWithdrawFor(address subAccount, uint256 numShares) external;

    function collaterals(uint256 index) external view returns (Collateral memory);

    function expiry(uint256 round) external view returns (uint256);

    function pricePerShare(uint256 round) external view returns (uint256);

    function getCollaterals() external view returns (Collateral[] memory);

    function getStartingBalances(uint256 round) external view returns (uint256[] memory);

    function getCollateralPrices(uint256 round) external view returns (uint256[] memory);
}