//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IGakkoLoot.sol";
import "./IGakkoRewards.sol";
import "./IStakingProvider.sol";
import "../Common/Delegated.sol";


contract GakkoRewards is Delegated, IGakkoRewards{
  event LootAwarded(uint256 indexed tokenId, uint16 level);
  event LootClaimed(uint256 indexed tokenId, uint16 level);

  error AlreadyClaimed();
  error IncorrectOwner();
  error LengthMistmatch();
  error NonexistentLevel();

  bool public isRewardsEnabled;
  string public name = "Gakko Rewards";
  uint16 public totalSupply;
  uint32[] public rewardTimes;
  IStakingProvider public stakingProvider;
  mapping(uint16 => uint16) public tokenLevel;
  mapping(uint16 => IGakkoLoot) public lootProviders;

  constructor()
    Delegated()
  // solhint-disable-next-line no-empty-blocks
  {}


  //nonpayable - delegate callbacks
  function handleRewards( StakeSummary[] calldata claims ) external onlyDelegates{
    if( !isRewardsEnabled ) return;


    uint16[] memory allTokenIds = new uint16[]( claims.length );
    for( uint256 i = 0; i < claims.length; ++i ){
      allTokenIds[i] = claims[i].tokenId;
    }
    address[] memory allOwners = stakingProvider.ownerOfAll(allTokenIds);


    uint16 tokenId;
    StakeSummary memory claim;
    for( uint256 i = 0; i < claims.length; ++i ){
      claim = claims[i];
      tokenId = claim.tokenId;

      for(uint16 level = tokenLevel[tokenId]; level < rewardTimes.length; ++level ){
        if(rewardTimes[level] <= claim.total){
          ++tokenLevel[tokenId];

          lootProviders[level].handleClaim(allOwners[i], Token(
            tokenId,
            level,
            true
          ));

          emit LootAwarded(tokenId, level);
        }
        else
          break;
      }
    }
  }

  // solhint-disable-next-line no-empty-blocks
  function handleStakes( uint16[] calldata tokenIds ) external onlyDelegates{}


  //nonpayable - owner
  function mintTo(uint16[] calldata tokenIds) external onlyDelegates{
    address[] memory allOwners = stakingProvider.ownerOfAll(tokenIds);
    for(uint256 t = 0; t < tokenIds.length; ++t ){
      uint16 tokenId = tokenIds[t];
      for(uint16 level = tokenLevel[tokenId]; level < rewardTimes.length; ++level ){
        ++tokenLevel[tokenId];

        lootProviders[level].handleClaim(allOwners[t], Token(
          tokenId,
          level,
          true
        ));
      }
    }
  }

  function setEnabled(bool rewardsEnabled) external onlyDelegates{
    isRewardsEnabled = rewardsEnabled;
  }

  function setLootProvider(uint16 level, IGakkoLoot provider) external onlyDelegates{
    lootProviders[level] = provider;
  }

  //set newTimes first, then increment maxTokenClaims
  function setRewardTimes(uint32[] calldata newTimes) external onlyDelegates{
    require( newTimes.length >= rewardTimes.length, "newTimes must be more than rewardTimes" );

    uint i = 0;
    for( ; i < rewardTimes.length; ++i ){
      rewardTimes[i] = newTimes[i];
    }

    for( ; i < newTimes.length; ++i ){
      rewardTimes.push( newTimes[i] );
    }
  }

  function setStakingProvider( IStakingProvider provider ) external onlyDelegates {
    stakingProvider = provider;
  }


  //view
  function getTokensLevels(uint16[] calldata tokenIds) external view returns(uint16[] memory){
    uint16[] memory levels = new uint16[](tokenIds.length);
    for(uint256 i = 0; i < tokenIds.length; ++i){
      levels[i] = tokenLevel[tokenIds[i]];
    }
    return levels;
  }
}