// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBTokenUriResolver.sol';
import './../structs/JB721TierParams.sol';
import './../structs/JB721Tier.sol';
import './../structs/JBTiered721Flags.sol';

interface IJBTiered721DelegateStore {
  event CleanTiers(address indexed nft, address caller);

  function totalSupply(address _nft) external view returns (uint256);

  function balanceOf(address _nft, address _owner) external view returns (uint256);

  function maxTierIdOf(address _nft) external view returns (uint256);

  function tiersOf(
    address _nft,
    uint256[] calldata _categories,
    bool _includeResolvedUri,
    uint256 _startingSortIndex,
    uint256 _size
  ) external view returns (JB721Tier[] memory tiers);

  function tierOf(
    address _nft,
    uint256 _id,
    bool _includeResolvedUri
  ) external view returns (JB721Tier memory tier);

  function tierBalanceOf(
    address _nft,
    address _owner,
    uint256 _tier
  ) external view returns (uint256);

  function tierOfTokenId(
    address _nft,
    uint256 _tokenId,
    bool _includeResolvedUri
  ) external view returns (JB721Tier memory tier);

  function tierIdOfToken(uint256 _tokenId) external pure returns (uint256);

  function encodedIPFSUriOf(address _nft, uint256 _tierId) external view returns (bytes32);

  // function firstOwnerOf(address _nft, uint256 _tokenId) external view returns (address);

  function redemptionWeightOf(
    address _nft,
    uint256[] memory _tokenIds
  ) external view returns (uint256 weight);

  function totalRedemptionWeight(address _nft) external view returns (uint256 weight);

  function numberOfReservedTokensOutstandingFor(
    address _nft,
    uint256 _tierId
  ) external view returns (uint256);

  function numberOfReservesMintedFor(address _nft, uint256 _tierId) external view returns (uint256);

  function numberOfBurnedFor(address _nft, uint256 _tierId) external view returns (uint256);

  function isTierRemoved(address _nft, uint256 _tierId) external view returns (bool);

  function flagsOf(address _nft) external view returns (JBTiered721Flags memory);

  function votingUnitsOf(address _nft, address _account) external view returns (uint256 units);

  function tierVotingUnitsOf(
    address _nft,
    address _account,
    uint256 _tierId
  ) external view returns (uint256 units);

  function defaultReservedTokenBeneficiaryOf(address _nft) external view returns (address);

  function reservedTokenBeneficiaryOf(
    address _nft,
    uint256 _tierId
  ) external view returns (address);

  function tokenUriResolverOf(address _nft) external view returns (IJBTokenUriResolver);

  function encodedTierIPFSUriOf(address _nft, uint256 _tokenId) external view returns (bytes32);

  function recordAddTiers(
    JB721TierParams[] memory _tierData
  ) external returns (uint256[] memory tierIds);

  function recordMintReservesFor(
    uint256 _tierId,
    uint256 _count
  ) external returns (uint256[] memory tokenIds);

  function recordBurn(uint256[] memory _tokenIds) external;

  function recordMint(
    uint256 _amount,
    uint16[] calldata _tierIds,
    bool _isManualMint
  ) external returns (uint256[] memory tokenIds, uint256 leftoverAmount);

  function recordTransferForTier(uint256 _tierId, address _from, address _to) external;

  function recordRemoveTierIds(uint256[] memory _tierIds) external;

  function recordSetTokenUriResolver(IJBTokenUriResolver _resolver) external;

  function recordSetEncodedIPFSUriOf(uint256 _tierId, bytes32 _encodedIPFSUri) external;

  function recordFlags(JBTiered721Flags calldata _flag) external;

  function cleanTiers(address _nft) external;
}