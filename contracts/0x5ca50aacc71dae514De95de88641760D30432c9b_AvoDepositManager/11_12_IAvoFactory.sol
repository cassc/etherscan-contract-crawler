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

    /// @notice           Checks if a certain address is an AvoSafe instance. only works for already deployed AvoSafes
    /// @param avoSafe_   address to check
    /// @return           true if address is an avoSafe
    function isAvoSafe(address avoSafe_) external view returns (bool);

    /// @notice         Computes the deterministic address for owner based on Create2
    /// @param owner_   AvoSafe Owner
    /// @return         computed address for the contract (AvoSafe)
    function computeAddress(address owner_) external view returns (address);

    /// @notice         Deploys an AvoSafe for a certain owner deterministcally using Create2.
    ///                 Does not check if contract at address already exists. AvoForwarder already does that.
    /// @param owner_   AvoSafe owner
    /// @return         deployed address for the contract (AvoSafe)
    function deploy(address owner_) external returns (address);

    /// @notice                    Deploys an AvoSafe with non-default version for an owner deterministcally using Create2.
    ///                            ATTENTION: Only supports AvoWallet version > 2.0.0
    ///                            Does not check if contract at address already exists. AvoForwarder already does that.
    /// @param owner_              AvoSafe owner
    /// @param avoWalletVersion_   Version of AvoWallet logic contract to deploy
    /// @return                    deployed address for the contract (AvoSafe)
    function deployWithVersion(address owner_, address avoWalletVersion_) external returns (address);

    /// @notice                   registry can update the current AvoWallet implementation contract
    ///                           set as default for new AvoSafe (proxy) deployments logic contract
    /// @param avoWalletImpl_     the new avoWalletImpl address
    function setAvoWalletImpl(address avoWalletImpl_) external;

    /// @notice      reads the byteCode for the AvoSafe contract used for Create2 address computation
    /// @return      the bytes32 byteCode for the contract
    function avoSafeBytecode() external view returns (bytes32);
}