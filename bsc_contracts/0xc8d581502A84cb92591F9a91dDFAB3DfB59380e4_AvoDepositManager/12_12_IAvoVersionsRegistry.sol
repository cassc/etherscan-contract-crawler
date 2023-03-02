// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface IAvoVersionsRegistry {
    /// @notice                   checks if an address is listed as allowed AvoWallet version and reverts if it is not
    /// @param avoWalletVersion_  address of the Avo wallet logic contract to check
    function requireValidAvoWalletVersion(address avoWalletVersion_) external view;

    /// @notice                      checks if an address is listed as allowed AvoForwarder version
    ///                              and reverts if it is not
    /// @param avoForwarderVersion_  address of the AvoForwarder logic contract to check
    function requireValidAvoForwarderVersion(address avoForwarderVersion_) external view;
}