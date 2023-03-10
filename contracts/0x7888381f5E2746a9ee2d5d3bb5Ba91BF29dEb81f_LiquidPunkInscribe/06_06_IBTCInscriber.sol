// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title Interface to the BTCInscriber registry developed by Layerr
 */

/// @dev struct containing registry information for each inscription request
struct InscribedNFT {
    address collectionAddress;
    uint256 tokenId;
    address inscribedBy;
    uint96 registryLockTime;
    bytes32 btcTransactionHash;
    string btcAddress;
}

/// @dev helper struct for getTokensOwnedByCollection
struct TokenStatus {
    address collectionAddress;
    uint256 tokenId;
    uint256 inscriptionIndex;
}

interface IBTCInscriber {
    function nftToInscriptionIndex(address collectionAddress, uint256 tokenId) external view returns(uint256);
    function inscribedNFTs(uint256 inscriptionIndex) external view returns(InscribedNFT memory);
    function inscriptionBaseFee() external view returns(uint256);
    function registerOnlyFee() external view returns(uint256);
    function inscriptionDiscount(address collectionAddress) external view returns(uint256);
    function inscribeNFT(address collectionAddress, uint256 tokenId, string calldata btcAddress) external payable;
    function inscribeNFTBatch(address[] calldata collectionAddresses, uint256[] calldata tokenIds, string[] calldata btcAddresses) external payable;
    function updateBTCAddress(address collectionAddress, uint256 tokenId, string calldata btcAddress) external;
    function updateBTCAddressBatch(address[] calldata collectionAddresses, uint256[] calldata tokenIds, string[] calldata btcAddresses) external;
    function registerInscription(address collectionAddress, uint256 tokenId, bytes32 btcTransactionHash) external payable;
    function registerInscriptionBatch(address[] calldata collectionAddresses, uint256[] calldata tokenIds, bytes32[] calldata btcTransactionHashes) external payable;
    function updateTransactionHash(address collectionAddress, uint256 tokenId, bytes32 btcTransactionHash, string calldata btcAddress) external;
    function updateTransactionHashBatch(address[] calldata collectionAddresses, uint256[] calldata tokenIds, bytes32[] calldata btcTransactionHashes, string[] calldata btcAddresses) external;
    function inscriptionsByOwner(address tokenOwner) external view returns(InscribedNFT[] memory _inscriptions);
    function allInscriptions(address collectionAddress, bool includePending, bool includeCompleted, bool sortNewestFirst, uint256 maxRecords) external view returns(InscribedNFT[] memory _inscriptions);
}