// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface INftDistributor {
  event ContractReady(address indexed intializer);
  event TaggrSet(address indexed taggr);
  event TaggrSettingsSet(address indexed taggrSettings);
  event CustomerSettingsSet(address indexed customerSettings);
  event TokenEscrowSet(address indexed tokenEscrow);
  event NftClaimed(address indexed to, address indexed contractAddress, uint256 tokenId);
  event NftPurchased(address indexed to, address indexed contractAddress, uint256 tokenId, bool mintPass);
  event PhysicalDeliveryTimestamp(string indexed projectId, address indexed contractAddress, uint256 tokenId, uint256 timestamp);

  function isFullyClaimed(address contractAddress, uint256 tokenId) external view returns (bool isClaimed);

  function hasValidClaim(
    address contractAddress,
    bytes32 merkleNode,
    bytes32[] calldata merkleProof
  ) external view returns (bool);

  function claimNft(
    address contractAddress,
    uint256 tokenId,
    bytes32 merkleNode,
    bytes32[] calldata merkleProof
  ) external;

  function mintNftWithPass(string calldata projectId, address contractAddress, uint256 tokenId) external payable;

  function purchaseNft(string calldata projectId, address contractAddress, uint256 tokenId) external payable;
  function purchaseNftWithPermit(
    string calldata projectId,
    address contractAddress,
    uint256 tokenId,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external payable;
}