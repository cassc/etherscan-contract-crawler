// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

error CollectionAddressCannotBeZero();
error CollectionAlreadyExists();
error CollectionAlreadySponsored();
error CollectionAlreadyVerified();
error CollectionDoesNotExist(address collection);
error CollectionHasMintedTokens();
error CollectionMetadataNotAvailable();
error CollectionNotSponsored();
error CollectionNotSponsoredBySender();
error NotEnoughAllowance();
error NotEnoughBalance();
error OnlyCollectionOwnerCanRemoveCollection();
error OnlyOwnerAdminOrFactoryCanAddCollection();

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
        address collection,
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

    event CollectionBlacklisted(address collection);
    event CollectionRemoved(address collection);
    event CollectionSponsorshipCancelled(address collection);
    event CollectionSponsored(address collection, address sponsor);
    event CollectionUnverified(address collection);
    event CollectionVerified(address collection);

    function addCollectionFromFactories(
        address collection,
        address deployer,
        uint256 maxSupply,
        LegoCombination legoCombination,
        MintingType mintingType,
        bool isSoulbound
    ) external;

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

    function getMetaFactoryAddress() external view returns (address);
}