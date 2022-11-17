//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./BucketAuction.sol";
import "./Shared/IGakkoRewards.sol";
import "./Shared/IStakingProvider.sol";

contract StakedBucketAuction is IStakingProvider, BucketAuction{
  event StakeClaimed( uint16 indexed tokenId, uint32 timestamp, uint32 collected );
  event TokenStaked( uint16 indexed tokenId, uint32 timestamp );
  event TokenUnstaked( uint16 indexed tokenId, uint32 timestamp );

  error IncorrectOwner();
  error InvalidConfig();
  error InvalidStake();
  error NoTokensSpecified();
  error StakingInactive();
  error TransferWhileStaked();

  struct StakeData{
    uint32 started; // 32
    uint32 total;   // 64
  }

  uint32 public baseAward;
  bool public isStakeable;
  IGakkoRewards public rewardHandler;
  mapping(uint16 => StakeData) public stakes;

  constructor(
    string memory collectionName,
    string memory collectionSymbol,
    string memory tokenURISuffix,
    uint256 maxMintableSupply,
    uint256 globalWalletLimit,
    address cosigner,
    uint256 minimumContributionInWei,
    uint64 startTimeUnixSeconds,
    uint64 endTimeUnixSeconds
  )
    BucketAuction(
      collectionName,
      collectionSymbol,
      tokenURISuffix,
      maxMintableSupply,
      globalWalletLimit,
      cosigner,
      minimumContributionInWei,
      startTimeUnixSeconds,
      endTimeUnixSeconds
    )
  {
    baseAward = 0;
  }


  //nonpayable - public
  function claimTokens(uint16[] calldata tokenIds, bool restake) external {
    if (tokenIds.length == 0) revert NoTokensSpecified();

    uint256 length = tokenIds.length;
    uint32 time = uint32(block.timestamp);
    StakeSummary[] memory claims = new StakeSummary[](tokenIds.length);
    for (uint256 i = 0; i < length; ++i ) {
      //checks
      uint16 tokenId = tokenIds[i];
      if (ERC721A.ownerOf( tokenId ) != msg.sender) revert IncorrectOwner();

      StakeData memory stake = stakes[ tokenId ];
      if (stake.started < 2) {
        claims[i] = StakeSummary(
          stake.total,
          stake.total,
          tokenId
        );
      }
      else{
        uint32 accrued = ( time - stake.started );
        if (stake.total == 0)
          accrued += baseAward;

        claims[i] = StakeSummary(
          stake.total,
          stake.total + accrued,
          tokenId
        );

        //effects
        stakes[tokenId] = StakeData(
          restake ? time : 1,
          stake.total + accrued
        );

        emit StakeClaimed( tokenId, time, accrued );

        if(!restake)
          emit TokenUnstaked(tokenId, time);
      }
    }

    //interactions
    if(address(rewardHandler) != address(0)){
      rewardHandler.handleRewards(claims);
    }
  }

  function stakeTokens( uint16[] calldata tokenIds ) external {
    if (tokenIds.length == 0) revert NoTokensSpecified();
    if (!isStakeable) revert StakingInactive();

    uint256 length = tokenIds.length;
    uint32 time = uint32(block.timestamp);
    for (uint256 i = 0; i < length; ++i) {
      //checks
      uint16 tokenId = tokenIds[i];
      if (ERC721A.ownerOf(tokenId) != msg.sender) revert IncorrectOwner();

      StakeData storage stake = stakes[ tokenId ];
      if (stake.started < 2) {
        //effects
        stake.started = time;
        emit TokenStaked( tokenId, time );
      }
    }

    //interactions
    if(address(rewardHandler) != address(0))
      rewardHandler.handleStakes(tokenIds);
  }


  //payable - public - override
  function transferFrom(address from, address to, uint256 tokenId)
    public
    payable
    override(ERC721A, IERC721A) {
    if (_isStaked(tokenId)) revert TransferWhileStaked();

    ERC721A.transferFrom( from, to, tokenId );
  }


  //nonpayable - admin
  function setBaseAward( uint32 award ) external onlyOwner{
    baseAward = award;
  }

  function setHandler( IGakkoRewards handler ) external onlyOwner{
    rewardHandler = handler;
  }

  function setStakeable( bool stakeable ) external onlyOwner{
    isStakeable = stakeable;
  }


  //view - public
  function getRewardHandler() external view returns(address){
    return address(rewardHandler);
  }

  function getStakeInfo( uint16[] calldata tokenIds ) external view returns (StakeInfo[] memory infos) {
    uint32 time = uint32(block.timestamp);

    infos = new StakeInfo[]( tokenIds.length );
    for(uint256 i; i < tokenIds.length; ++i ){
      StakeData memory stake = stakes[ tokenIds[i] ];
      if( stake.started > 1 ){
        uint32 pending = time - stake.started;
        if( stake.total == 0 )
          pending += baseAward;

        infos[i] = StakeInfo(
          tokenIds[i],
          stake.total,
          pending,
          true
        );
      }
      else{
        infos[i] = StakeInfo(
          tokenIds[i],
          stake.total,
          0,
          false
        );
      }
    }
  }


  //view - override
  function ownerOf(uint256 tokenId)
    public
    view
    override(ERC721A, IERC721A)
    returns( address currentOwner ) {
    if (tokenId > type(uint16).max || !_exists(tokenId))
      revert URIQueryForNonexistentToken();

    if(_isStaked(tokenId))
      currentOwner = address(this);
    else
      currentOwner = ERC721A.ownerOf(tokenId);
  }

  function ownerOfAll(uint16[] calldata tokenIds) external view returns(address[] memory owners){
    uint256 length = tokenIds.length;
    owners = new address[]( length );
    for(uint256 i = 0; i < length; ++i){
      owners[i] = ERC721A.ownerOf(tokenIds[i]);
    }
  }

  //view - internal
  function _isStaked( uint256 tokenId ) internal view returns( bool ){
    return stakes[uint16(tokenId)].started > 1;
  }
}