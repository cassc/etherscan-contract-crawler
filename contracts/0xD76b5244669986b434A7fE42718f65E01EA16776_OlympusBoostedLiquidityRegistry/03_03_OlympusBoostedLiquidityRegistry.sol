// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

import {BLREGv1} from "src/modules/BLREG/BLREG.v1.sol";
import "src/Kernel.sol";

/// @title  Olympus Boosted Liquidity Vault Registry
/// @notice Olympus Boosted Liquidity Vault Registry (Module) Contract
/// @dev    The Olympus Boosted Liquidity Vault Registry Module tracks the boosted liquidity vaults
///         that are approved to be used by the Olympus protocol. This allows for a single-soure
///         of truth for reporting purposes around total OHM deployed and net emissions.
contract OlympusBoostedLiquidityRegistry is BLREGv1 {
    //============================================================================================//
    //                                      MODULE SETUP                                          //
    //============================================================================================//

    constructor(Kernel kernel_) Module(kernel_) {}

    /// @inheritdoc Module
    function KEYCODE() public pure override returns (Keycode) {
        return toKeycode("BLREG");
    }

    /// @inheritdoc Module
    function VERSION() public pure override returns (uint8 major, uint8 minor) {
        major = 1;
        minor = 0;
    }

    //============================================================================================//
    //                                       CORE FUNCTIONS                                       //
    //============================================================================================//

    /// @inheritdoc BLREGv1
    function addVault(address vault_) external override permissioned {
        activeVaults.push(vault_);
        ++activeVaultCount;

        emit VaultAdded(vault_);
    }

    /// @inheritdoc BLREGv1
    function removeVault(address vault_) external override permissioned {
        // Find index of vault in array
        for (uint256 i; i < activeVaultCount; ) {
            if (activeVaults[i] == vault_) {
                // Delete vault from array by swapping with last element and popping
                activeVaults[i] = activeVaults[activeVaults.length - 1];
                activeVaults.pop();
                --activeVaultCount;
                break;
            }

            unchecked {
                ++i;
            }
        }

        emit VaultRemoved(vault_);
    }
}