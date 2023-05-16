//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

library FactoryErrors {
    error ZeroPoolAddress();
    error NoVaultInitDataProvided();
    error MismatchedVaultsAndImplsLength();
    error VaultUpgradeFailed();
}