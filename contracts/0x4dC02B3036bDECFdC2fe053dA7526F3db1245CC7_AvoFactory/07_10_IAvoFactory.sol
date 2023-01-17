// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { IAvoVersionsRegistry } from "./IAvoVersionsRegistry.sol";

interface IAvoFactory {
    /// @notice AvoVersionsRegistry (proxy) address
    /// @return contract address
    function avoVersionsRegistry() external view returns (IAvoVersionsRegistry);

    /// @notice Avo wallet logic contract address that new AvoSafe deployments point to
    /// @return contract address
    function avoWalletImpl() external view returns (address);

    /// @notice         Computes the deterministic address for owner based on Create2
    /// @param owner_   AvoSafe Owner
    /// @return         computed address for the contract (AvoSafe)
    function computeAddress(address owner_) external view returns (address);

    /// @notice         Deploys an AvoSafe for a certain owner deterministcally using Create2.
    ///                 Does not check if contract at address already exists. AvoForwarder already does that.
    /// @param owner_   AvoSafe owner
    /// @return         deployed address for the contract (AvoSafe)
    function deploy(address owner_) external returns (address);

    /// @notice                   registry can update the current AvoWallet implementation contract
    ///                           set as default for new AvoSafe (proxy) deployments logic contract
    /// @param avoWalletImpl_     the new avoWalletImpl address
    function setAvoWalletImpl(address avoWalletImpl_) external;

    /// @notice      reads the byteCode for the AvoSafe contract used for Create2 address computation
    /// @return      the bytes32 byteCode for the contract
    function avoSafeBytecode() external view returns (bytes32);
}