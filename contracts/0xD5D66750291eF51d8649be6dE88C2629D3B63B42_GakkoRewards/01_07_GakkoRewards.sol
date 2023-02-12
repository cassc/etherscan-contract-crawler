//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IGakkoLoot.sol";
import "./IGakkoRewards.sol";
import "./IStakingProvider.sol";
import "../Common/Delegated.sol";


contract GakkoRewards is Delegated, IGakkoRewards{
  event LootAwarded(uint256 indexed tokenId, uint16 level);

  error NoTokensSpecified();
  error OwnerMismatch();
  error UnbalancedRequest();

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
  function handleRewards(StakeSummary[] calldata claims) external onlyDelegates{
    if( !isRewardsEnabled ) return;
    if(claims.length == 0)
      revert NoTokensSpecified();


    uint16 startLevel = uint16(rewardTimes.length);
    TokenList[] memory levelClaims = new TokenList[](rewardTimes.length);

    uint16[] memory checkTokens = new uint16[](1);
    checkTokens[0] = claims[0].tokenId;
    address owner = stakingProvider.ownerOfAll(checkTokens)[0];

    unchecked{
      //uint16 count;
      uint16 tokenId;
      StakeSummary memory claim;
      for(uint256 i = 0; i < claims.length; ++i){
        claim = claims[i];
        tokenId = claim.tokenId;
        for(uint16 level = tokenLevel[tokenId]; level < rewardTimes.length; ++level ){
          if(rewardTimes[level] <= claim.total){
            if(startLevel > level)
              startLevel = level;

            ++tokenLevel[tokenId];
            uint16 count = levelClaims[level].length++;
            if(count == 0)
              levelClaims[level].tokens = new Token[](claims.length - i);

            levelClaims[level].tokens[count] = Token(
              owner,
              tokenId,
              level,
              true
            );
          }
        }
      }

      _claimRewards(levelClaims, owner, startLevel);
    }
  }

  // solhint-disable-next-line no-empty-blocks
  function handleStakes( uint16[] calldata tokenIds ) external onlyDelegates{}


  //nonpayable - owner
  function setLevels(uint16[] calldata tokenIds, uint16 level) external onlyDelegates{
    uint16 tokenId;
    for(uint256 i = 0; i < tokenIds.length; ++i){
      tokenId = tokenIds[i];
      tokenLevel[tokenId] = level;
      emit LootAwarded(tokenId, level);
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


  //internal
  function _claimRewards(TokenList[] memory levelClaims, address owner, uint16 startLevel) private {
    unchecked{
      TokenList memory list;
      for(uint16 level = startLevel; level < rewardTimes.length; ++level){
        list = levelClaims[level];
        if(list.length > 0){
          lootProviders[level].handleClaims(owner, list);

          for(uint256 i = 0; i < list.length; ++i){
            emit LootAwarded(list.tokens[i].parentId, level);
          }
        }
      }
    }
  }
}