// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {Vault} from "../libraries/Vault.sol";

interface IRibbonThetaVault {
    function GAMMA_CONTROLLER() external view returns (address);

    function currentOption() external view returns (address);

    function nextOption() external view returns (address);

    function vaultParams() external view returns (Vault.VaultParams memory);

    function vaultState() external view returns (Vault.VaultState memory);

    function optionState() external view returns (Vault.OptionState memory);

    function optionAuctionID() external view returns (uint256);

    function pricePerShare() external view returns (uint256);

    function roundPricePerShare(uint256) external view returns (uint256);

    function symbol() external view returns (string calldata);

    function depositFor(uint256 amount, address creditor) external;

    function initiateWithdraw(uint256 numShares) external;

    function completeWithdraw() external;

    function maxRedeem() external;

    function commitAndClose() external;

    function burnRemainingOTokens() external;
}

interface IRibbonTreasuryVault is IRibbonThetaVault {
    function period() external view returns (uint256);
}

interface IRibbonSTETHVault is IRibbonThetaVault {
    function depositYieldTokenFor(uint256 amount, address creditor) external;
}