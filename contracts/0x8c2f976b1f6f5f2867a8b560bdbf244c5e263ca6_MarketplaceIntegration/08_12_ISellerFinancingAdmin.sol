//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/// @title NiftyApes interface for the admin role.
interface ISellerFinancingAdmin {
    /// @notice Pauses all interactions with the contract.
    ///         This is intended to be used as an emergency measure to avoid loosing funds.
    function pause() external;

    /// @notice Unpauses all interactions with the contract.
    function unpause() external;

    /// @notice Pauses sanctions checks
    function pauseSanctions() external;

    /// @notice Unpauses sanctions checks
    function unpauseSanctions() external;

    /// @notice Updates royalty engine contract address to new address
    /// @param newRoyaltyEngineContractAddress New royalty engine address
    function updateRoyaltiesEngineContractAddress(address newRoyaltyEngineContractAddress) external;

    /// @notice Updates delegate registry contract address to new address
    /// @param newDelegateRegistryContractAddress New delegate registry address
    function updateDelegateRegistryContractAddress(
        address newDelegateRegistryContractAddress
    ) external;

    /// @notice Updates seaport contract address to new address
    /// @param newSeaportContractAddress New seaport address
    function updateSeaportContractAddress(address newSeaportContractAddress) external;

    /// @notice Updates Weth contract address to new address
    /// @param newWethContractAddress New Weth contract address
    function updateWethContractAddress(address newWethContractAddress) external;
}