// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

import "../ERC721AUpgradeable.sol";

/// @title IBaseLaunchpeg
/// @author Trader Joe
/// @notice Defines the basic interface of BaseLaunchpeg
interface IBaseLaunchpeg is IERC721Upgradeable, IERC721MetadataUpgradeable {
    enum Phase {
        NotStarted,
        DutchAuction,
        PreMint,
        Allowlist,
        PublicSale,
        Ended
    }

    /// @notice Collection data to initialize Launchpeg
    /// @param name ERC721 name
    /// @param symbol ERC721 symbol
    /// @param maxPerAddressDuringMint Max amount of NFTs an address can mint in public phases
    /// @param collectionSize The collection size (e.g 10000)
    /// @param amountForDevs Amount of NFTs reserved for `projectOwner` (e.g 200)
    /// @param amountForAuction Amount of NFTs available for the auction (e.g 8000)
    /// @param amountForAllowlist Amount of NFTs available for the allowlist mint (e.g 1000)
    struct CollectionData {
        string name;
        string symbol;
        address batchReveal;
        uint256 maxPerAddressDuringMint;
        uint256 collectionSize;
        uint256 amountForDevs;
        uint256 amountForAuction;
        uint256 amountForAllowlist;
    }

    /// @notice Collection owner data to initialize Launchpeg
    /// @param owner The contract owner
    /// @param projectOwner The project owner
    /// @param royaltyReceiver Royalty fee collector
    /// @param joeFeeCollector The address to which the fees on the sale will be sent
    /// @param joeFeePercent The fees collected by the fee collector on the sale benefits
    struct CollectionOwnerData {
        address owner;
        address projectOwner;
        address royaltyReceiver;
        address joeFeeCollector;
        uint256 joeFeePercent;
    }

    function PROJECT_OWNER_ROLE() external pure returns (bytes32);

    function collectionSize() external view returns (uint256);

    function unrevealedURI() external view returns (string memory);

    function baseURI() external view returns (string memory);

    function amountForDevs() external view returns (uint256);

    function amountForAllowlist() external view returns (uint256);

    function maxPerAddressDuringMint() external view returns (uint256);

    function joeFeePercent() external view returns (uint256);

    function joeFeeCollector() external view returns (address);

    function allowlist(address) external view returns (uint256);

    function amountMintedByDevs() external view returns (uint256);

    function amountMintedDuringPreMint() external view returns (uint256);

    function amountClaimedDuringPreMint() external view returns (uint256);

    function amountMintedDuringAllowlist() external view returns (uint256);

    function amountMintedDuringPublicSale() external view returns (uint256);

    function preMintStartTime() external view returns (uint256);

    function allowlistStartTime() external view returns (uint256);

    function publicSaleStartTime() external view returns (uint256);

    function publicSaleEndTime() external view returns (uint256);

    function withdrawAVAXStartTime() external view returns (uint256);

    function allowlistPrice() external view returns (uint256);

    function salePrice() external view returns (uint256);

    function initializeBatchReveal(address _batchReveal) external;

    function setRoyaltyInfo(address receiver, uint96 feePercent) external;

    function seedAllowlist(
        address[] memory _addresses,
        uint256[] memory _numSlots
    ) external;

    function setBaseURI(string calldata baseURI) external;

    function setUnrevealedURI(string calldata baseURI) external;

    function setPreMintStartTime(uint256 _preMintStartTime) external;

    function setAllowlistStartTime(uint256 _allowlistStartTime) external;

    function setPublicSaleStartTime(uint256 _publicSaleStartTime) external;

    function setPublicSaleEndTime(uint256 _publicSaleEndTime) external;

    function setWithdrawAVAXStartTime(uint256 _withdrawAVAXStartTime) external;

    function devMint(uint256 quantity) external;

    function preMint(uint96 _quantity) external payable;

    function claimPreMint() external;

    function batchClaimPreMint(uint96 _maxQuantity) external;

    function allowlistMint(uint256 _quantity) external payable;

    function publicSaleMint(uint256 _quantity) external payable;

    function withdrawAVAX(address to) external;

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (ERC721AUpgradeable.TokenOwnership memory);

    function userPendingPreMints(address owner) external view returns (uint256);

    function numberMinted(address owner) external view returns (uint256);

    function numberMintedWithPreMint(address _owner)
        external
        view
        returns (uint256);

    function currentPhase() external view returns (Phase);

    function revealNextBatch() external;

    function hasBatchToReveal() external view returns (bool, uint256);
}