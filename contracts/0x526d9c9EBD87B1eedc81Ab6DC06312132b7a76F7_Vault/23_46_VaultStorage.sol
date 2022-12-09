// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {IVaultFactory} from "../interfaces/IVaultFactory.sol";

/**
 * @title Vault Storage
 * @author Immunefi
 * @notice We use vault storage contracts to keep upgradeability
 */
contract VaultStorageV1 is Ownable2StepUpgradeable {
    IVaultFactory public vaultFactory;
    bool public isPausedOnImmunefi;
}