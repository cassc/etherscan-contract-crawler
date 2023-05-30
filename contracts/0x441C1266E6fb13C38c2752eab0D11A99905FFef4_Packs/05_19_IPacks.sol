// SPDX-License-Identifier: MIT
// Written by Tim Kang <> illestrater
// Thought innovation by Monstercat
// Product by universe.xyz

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import './LibPackStorage.sol';
import "@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol";

/// @title Creators can release NFTs with multiple collectibles, across multiple collections/drops, and buyers will receive a random tokenID
/// @notice This interface should be implemented by the Packs contract
/// @dev This interface should be implemented by the Packs contract
interface IPacks is IERC721Enumerable {

  /* 
   * cID refers to collection ID
   * Should not have more than 1000 editions of the same collectible (gas limit recommended, technically can support ~4000 editions)
  */

  /// @notice Transfers contract ownership to DAO / different address
  /// @param _daoAddress The new address
  function transferDAOownership(address payable _daoAddress) external;

  /// @notice Creates a new collection / drop (first collection is created via constructor)
  /// @param _baseURI Base URI (e.g. https://arweave.net/)
  /// @param _editioned Toggle to show edition # in returned metadata
  /// @param _initParams Initialization parameters in array [token price, bulk buy max quantity, start time of sale]
  /// @param _licenseURI Global license URI of collection / drop
  /// @param _mintPass ERC721 contract address to allow 1 free mint prior to sale start time
  /// @param _mintPassDuration Duration before sale start time allowing free mints
  /// @param _mintPassParams Array of params for mintPass [One Per Wallet, Mint Pass ONLY, Mint Pass Free Mint, Mint Pass Burn]
  function createNewCollection(string memory _baseURI, bool _editioned, uint256[] memory _initParams, string[] memory _metadataKeys, string memory _licenseURI, address _mintPass, uint256 _mintPassDuration, bool[] memory _mintPassParams) external;
  
  /// @notice Add multiple collectibles in one function call, same parameters as addCollectible but in array
  /// @param cID Collection ID
  /// @param _coreData Array of parameters [title, description, # of NFTs, current artwork version index starting 1]
  /// @param _editions Number of NFTs per asset
  /// @param _assets Array of artwork assets, starting index 0 indicative of version 1
  /// @param _metadataValues Array of key value pairs for property name and value
  /// @param _fees Array of different percentage payout splits on secondary sales
  function bulkAddCollectible(uint256 cID, string[][] memory _coreData, uint16[] memory _editions, string[][] memory _assets, LibPackStorage.MetadataStore[][] memory _metadataValues, LibPackStorage.Fee[][] memory _fees) external;
  
  /// @notice Mints an NFT with random token ID
  /// @param cID Collection ID
  /// @param mintPassTokenId Provide token ID to use as mint pass if appicable
  function mintPack(uint256 cID, uint256 mintPassTokenId) external payable;

  /// @notice Mints multiple NFTs with random token IDs
  /// @param cID Collection ID
  /// @param amount # of NFTs to mint
  function bulkMintPack(uint256 cID, uint256 amount) external payable;

  /// @notice Returns if an NFT was used as mint pass claim
  /// @param cID Collection ID
  /// @param tokenId NFT tokenID
  function mintPassClaimed(uint256 cID, uint256 tokenId) external view returns (bool);

  /// @notice Returns remaining NFTs available to purchase
  /// @param cID Collection ID
  function remainingTokens(uint256 cID) external view returns (uint256);

  /// @notice Updates metadata value given property is editable
  /// @param cID Collection ID
  /// @param collectibleId Collectible index (value 1 is index 0)
  /// @param propertyIndex Index of property to update (value 0 is index 0)
  /// @param value Value of property to update
  function updateMetadata(uint256 cID, uint256 collectibleId, uint256 propertyIndex, string memory value) external;

  /// @notice Adds new URI version with provided asset
  /// @param cID Collection ID
  /// @param collectibleId Collectible index (value 1 is index 0)
  /// @param asset Asset hash without baseURI included
  function addVersion(uint256 cID, uint256 collectibleId, string memory asset) external;

  /// @notice Adds new license URL for collection, auto increments license version number
  /// @param cID Collection ID
  /// @param _license Full URL of license
  function addNewLicense(uint256 cID, string memory _license) external;

  /// @notice Gets license given a license version
  /// @param cID Collection ID
  /// @param versionNumber Version number of license
  function getLicense(uint256 cID, uint256 versionNumber) external view returns (string memory);

  /// @notice Returns number of collections
  function getCollectionCount() external view returns (uint256);

    /// @notice Returns collection configured settings
  function getCollectionInfo(uint256 cID) external view returns (string memory);

  /// @notice Dynamically generates tokenURI as base64 encoded JSON of on-chain metadata
  /// @param tokenId NFT/Token ID number
  function tokenURI(uint256 tokenId) external view returns (string memory);

  /// @notice Returns addresses of secondary sale fees (Rarible Royalties Standard)
  /// @param tokenId NFT/Token ID number
  function getFeeRecipients(uint256 tokenId) external view returns (address payable[] memory);

  /// @notice Returns basis point values of secondary sale fees (Rarible Royalties Standard)
  /// @param tokenId NFT/Token ID number
  function getFeeBps(uint256 tokenId) external view returns (uint256[] memory);

  /// @notice Returns address and value of secondary sale fee (EIP-2981 royalties standard)
  /// @param tokenId NFT/Token ID number
  /// @param value ETH/ERC20 value to calculate from
  function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address recipient, uint256 amount);
}