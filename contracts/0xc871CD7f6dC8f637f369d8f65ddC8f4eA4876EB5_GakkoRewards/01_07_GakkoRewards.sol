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

  struct LootConfig{
    uint16 maxSupply;
    bool isActive;
  }

  bool public isClaimsEnabled;
  bool public isRewardsEnabled;
  string public name = "Gakko Rewards";
  uint16 public totalSupply;
  uint32[] public rewardTimes;
  IStakingProvider public stakingProvider;
  mapping(uint16 => Token[]) public loot;
  mapping(uint16 => IGakkoLoot) public lootProviders;

  constructor()
    Delegated()
  // solhint-disable-next-line no-empty-blocks
  {}


  //nonpayable - public
  function claimLoot( uint16[] calldata tokenIds, uint16[] calldata levels ) external{
    if(!isClaimsEnabled) return;

    if(tokenIds.length != levels.length) revert LengthMistmatch();

    uint256 length = tokenIds.length;
    address[] memory owners = stakingProvider.ownerOfAll(tokenIds);
    for( uint256 i = 0; i < length; ++i ){
      if(msg.sender != owners[i]) revert IncorrectOwner();

      uint16 level = levels[i];
      uint16 tokenId = tokenIds[i];
      if(level >= loot[tokenId].length) revert NonexistentLevel();

      Token storage token = loot[tokenId][level];
      if(token.isClaimed) revert AlreadyClaimed();

      token.isClaimed = true;
      lootProviders[token.level].handleClaim(msg.sender, token);

      emit LootClaimed(tokenId, level);
    }
  }


  //nonpayable - delegate callbacks
  function handleRewards( StakeSummary[] calldata claims ) external onlyDelegates{
    if( !isRewardsEnabled ) return;


    StakeSummary memory claim;
    for( uint256 i = 0; i < claims.length; ++i ){
      claim = claims[i];

      uint32 check;
      uint16 level = uint16(loot[claim.tokenId].length);
      for(; level < rewardTimes.length; ++level ){
        check = rewardTimes[ level ];
        if( claim.initial < check && check <= claim.total ){
          loot[claim.tokenId].push(Token(
            claim.tokenId,
            level,
            false
          ));

          emit LootAwarded( claim.tokenId, level );
        }
        else
          break;
      }
    }
  }

  // solhint-disable-next-line no-empty-blocks
  function handleStakes( uint16[] calldata tokenIds ) external onlyDelegates{}


  //nonpayable - owner
  function mintTo(uint16[] calldata tokenIds, uint16[] calldata levels ) external onlyDelegates{
    if(tokenIds.length != levels.length) revert LengthMistmatch();

    uint256 length = tokenIds.length;
    for(uint256 t = 0; t < length; ++t ){
      uint16 tokenId = tokenIds[t];
      uint16 level = uint16(loot[ tokenId ].length);
      for(; level < levels[t]; ++level ){
        loot[tokenId].push(Token(
          tokenId,
          level,
          false
        ));
      }
    }
  }

  function setEnabled(bool claimsEnabled, bool rewardsEnabled) external onlyDelegates{
    isClaimsEnabled = claimsEnabled;
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
  function getTokensLoot(uint16[] calldata tokenIds) external view returns(Token[] memory tokensLoot){
    uint256 totalLoot = 0;
    for(uint256 i = 0; i < tokenIds.length; ++i){
      //Token[] memory x = loot[tokenIds[i]];
      totalLoot += loot[tokenIds[i]].length;
    }

    uint256 index = 0;
    Token[] memory loots;
    tokensLoot = new Token[](totalLoot);
    for(uint256 i = 0; i < tokenIds.length; ++i){
      loots = loot[tokenIds[i]];
      for(uint256 j = 0; j < loots.length; ++j){
        tokensLoot[index++] = loots[j];
      }
    }
  }
}