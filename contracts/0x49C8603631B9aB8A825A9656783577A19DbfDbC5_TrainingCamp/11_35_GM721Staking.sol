// SPDX-License-Identifier: MIT
// GM2 Contracts (last updated v0.0.1)
pragma solidity ^0.8.9;

import '../structs/GM721StakingStructs.sol';
import '../structs/DynamicMetadataStructs.sol';
import '../errors/GM721StakingErrors.sol';

abstract contract GM721Staking {
  mapping(address => mapping(uint256 => StakedNFT)) internal _stakedNFTs;

  event Stake(address collection, uint256 tokenId, uint256 startAt);
  event UnStake(address collection, uint256 tokenId, uint256 totalStakedTime);

  function getTokenStakingData(address collection, uint256 tokenId)
    external
    view
    returns (StakedNFT memory stakingData)
  {
    return _stakedNFTs[collection][tokenId];
  }

  function _stake(
    address collection,
    uint256 tokenId,
    uint256 offset
  ) internal {
    StakedNFT storage nFTStakingData = _stakedNFTs[collection][tokenId];
    if (_isInStaking(nFTStakingData)) revert TokenAlreadyInStaking(collection, tokenId);

    nFTStakingData.lastStartedStakedTime = block.timestamp - offset;
    nFTStakingData.whoStake = msg.sender;
    emit Stake(collection, tokenId, nFTStakingData.lastStartedStakedTime);
  }

  function _unStake(address collection, uint256 tokenId) internal {
    StakedNFT storage nFTStakingData = _stakedNFTs[collection][tokenId];
    if (!_isInStaking(nFTStakingData)) revert TokenIsNotInStaking(collection, tokenId);

    nFTStakingData.totalStakedTime =
      nFTStakingData.totalStakedTime +
      (block.timestamp - nFTStakingData.lastStartedStakedTime);
    nFTStakingData.lastStartedStakedTime = 0;
    nFTStakingData.whoStake = address(0);

    emit UnStake(collection, tokenId, nFTStakingData.totalStakedTime);
  }

  function _isInStaking(StakedNFT storage nFTStakingData) internal view returns (bool) {
    return nFTStakingData.lastStartedStakedTime > 0;
  }
}