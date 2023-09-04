// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

interface IRMRKRegistry {
    enum LegoCombination {
        None,
        MultiAsset,
        Nestable,
        NestableMultiAsset,
        Equippable,
        ERC721,
        ERC1155,
        Custom
    }

    enum MintingType {
        None,
        RMRKPreMint,
        RMRKLazyMintNativeToken,
        RMRKLazyMintERC20,
        Custom
    }

    struct CollectionConfig {
        bool usesOwnable;
        bool usesAccessControl;
        bool usesRMRKContributor;
        bool usesRMRKMintingUtils;
        bool usesRMRKLockable;
        bool hasStandardAssetManagement; // has addAssetEntry, addEquippableAssetEntry, addAssetToToken, etc
        bool hasStandardMinting; // has mint(address to, uint256 numToMint)
        bool hasStandardNestMinting; // has nestMint(address to, uint256 numToMint, uint256 destinationId)
        bool autoAcceptsFirstAsset;
        uint8 customLegoCombination;
        uint8 customMintingType;
        bytes32 adminRole; // Only for AccessControl users
    }

    struct Collection {
        address collection;
        address verificationSponsor;
        uint256 verificationFeeBalance;
        LegoCombination legoCombination;
        MintingType mintingType;
        bool isSoulbound;
        bool visible;
        bool verified;
        CollectionConfig config;
    }

    event CollectionAdded(
        address deployer,
        string name,
        string symbol,
        uint256 maxSupply,
        string collectionMetadata,
        LegoCombination legoCombination,
        MintingType mintingType,
        bool isSoulbound,
        CollectionConfig config
    );

    function addCollection(
        address collection,
        address deployer,
        uint256 maxSupply,
        LegoCombination legoCombination,
        MintingType mintingType,
        bool isSoulbound,
        CollectionConfig memory config,
        string memory collectionMetadata
    ) external;
}