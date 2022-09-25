// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { Vault } from "../libraries/Vault.sol";

interface INeuronThetaVault {
    function currentOption() external view returns (address);

    function nextOption() external view returns (address);

    function vaultParams() external view returns (Vault.VaultParams memory);

    function vaultState() external view returns (Vault.VaultState memory);

    function optionState() external view returns (Vault.OptionState memory);

    function optionAuctionID() external view returns (uint256);
}