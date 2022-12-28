// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

interface IVaultFactory {
    /**
     * @dev Emitted on vault created.
     * @param vault the address of the vault.
     **/
    event VaultCreated(address vault);

    /**
     * @dev Emitted on setting new treasury address.
     * @param treasuryAddress the address of treasury.
     **/
    event VaultFactorySetTreasuryAddress(address treasuryAddress);

    /**
     * @dev Emitted on fee changes.
     * @param fee amount to publish Vault.
     **/
    event VaultFactorySetFeeToPublishVault(uint256 fee);
}