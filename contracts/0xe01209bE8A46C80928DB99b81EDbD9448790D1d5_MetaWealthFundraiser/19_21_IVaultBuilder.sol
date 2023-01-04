// SPDX-License-Identifier: None
pragma solidity ^0.8.7;

/// @title MetaWealth Asset Fractionalizer Factory
/// @author Ghulam Haider
/// @notice Creates AssetVault ERC20 smart contracts for any NFT
interface IVaultBuilder {
    /// @notice Fired when an asset is fractionalized into vault
    /// @param collection is the NFT collection address
    /// @param tokenId is the NFT token ID within that collection
    /// @param vaultAddress is the address of new vault
    event AssetFractionalized(
        address indexed collection,
        uint256 indexed tokenId,
        address vaultAddress,
        address[] payees,
        uint256[] shares
    );

    /// @notice Fired when an asset is defractionalized from the vault
    /// @param collection is the NFT collection address
    /// @param tokenId is the NFT token ID within that collection
    /// @param calledBy is the address of the wallet that called this function
    event AssetDefractionalized(
        address indexed collection,
        uint256 indexed tokenId,
        address calledBy,
        address shareholder
    );

    event AssetVaultUpdated(address newImplementation, address operator);

    /// @notice Takes an NFT and creates the fractional contract of it
    /// @notice If inactive, no trades can occur for this asset
    /// @param collection is the address of NFT collection being brought in
    /// @param tokenId is the specific token ID within NFT collection
    /// @param _merkleProof is the sender's proof of being in MetaWealth's whitelist
    /// @return newVault is the reference to the newly created asset vault
    function fractionalize(
        address collection,
        uint256 tokenId,
        address[] calldata payees,
        uint256[] calldata shares,
        string memory assetVaultName,
        string memory assetVaultSymbol,
        bytes32[] calldata _merkleProof
    ) external returns (address newVault);

    function onDefractionalize(
        address collection,
        uint256 tokenId,
        address shareholder
    ) external returns (bool);
}