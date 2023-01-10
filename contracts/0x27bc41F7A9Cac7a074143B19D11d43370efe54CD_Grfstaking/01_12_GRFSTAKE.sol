// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.4;

import "./GRFToken.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Grfstaking is Ownable {
  uint256 public totalStaked;
  uint256 private rewardsPerDay = 10000000000000000000;//10 ether
  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint24 tokenId;
    uint48 timestamp;
    address owner;
  }
  struct StakedTokenInfo {
    uint24 tokenId;
    uint256 earned;
    uint48 stakedAt;
  }

  event NFTStaked(address owner, uint256 tokenId, uint256 value);
  event NFTUnstaked(address owner, uint256 tokenId, uint256 value);
  event Claimed(address owner, uint256 amount);

  // reference to the Block NFT contract
  IERC721Enumerable nft;
  GRF token;

  // maps tokenId to stake
  mapping(uint256 => Stake) public vault; 

   constructor(IERC721Enumerable _nft, GRF _token) { 
    nft = _nft;
    token = _token;
  }

  function stake(uint256[] calldata tokenIds) external {
    uint256 tokenId;
    totalStaked += tokenIds.length;
    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      require(nft.ownerOf(tokenId) == msg.sender, "not your token");
      require(vault[tokenId].tokenId == 0, 'already staked');
      nft.transferFrom(msg.sender, address(this), tokenId);
      emit NFTStaked(msg.sender, tokenId, block.timestamp);
      vault[tokenId] = Stake({
        owner: msg.sender,
        tokenId: uint24(tokenId),
        timestamp: uint48(block.timestamp)
      });
    }
  }

  function _unstakeMany(address account, uint256[] calldata tokenIds) internal {
    uint256 tokenId;
    totalStaked -= tokenIds.length;
    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      Stake memory staked = vault[tokenId];
      require(staked.owner == msg.sender, "not an owner");
      delete vault[tokenId];
      emit NFTUnstaked(account, tokenId, block.timestamp);
      nft.transferFrom(address(this), account, tokenId);
    }
  }

  function claim(uint256[] calldata tokenIds) external {
      _claim(msg.sender, tokenIds, false);
  }

  function claimForAddress(address account, uint256[] calldata tokenIds) external onlyOwner {
      _claim(account, tokenIds, true);
  }

  function unstake(uint256[] calldata tokenIds) external {
      _claim(msg.sender, tokenIds, true);
  }

  function _claim(address account, uint256[] calldata tokenIds, bool _unstake) internal {
    uint256 totalEarned = 0;
    uint256 tokenId;
    uint256 rewardmath = 0;

    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      Stake memory staked = vault[tokenId];
      require(staked.owner == account, "not an owner");
      uint256 stakedAt = staked.timestamp;
      rewardmath = rewardsPerDay * (block.timestamp - stakedAt) / 86400;
      totalEarned += rewardmath;
      vault[tokenId] = Stake({
        owner: account,
        tokenId: uint24(tokenId),
        timestamp: uint48(block.timestamp)
      });
    }
    
    if (totalEarned > 7*rewardsPerDay) {
      token.mint(account, totalEarned);
    }
    if (_unstake) {
      _unstakeMany(account, tokenIds);
    }
    emit Claimed(account, totalEarned);
  }

  function earningInfo(address account, uint256[] calldata tokenIds) external view returns (StakedTokenInfo[] memory info) {
     uint256 tokenId;
     uint256 rewardmath = 0;
    StakedTokenInfo[] memory infoArray=new StakedTokenInfo[](tokenIds.length);
     for (uint i = 0; i < tokenIds.length; i++) {
        tokenId = tokenIds[i];
        Stake memory staked = vault[tokenId];
        require(staked.owner == account, "not an owner");
        uint256 stakedAt = staked.timestamp;
        rewardmath = rewardsPerDay * (block.timestamp - stakedAt) / 86400;
        StakedTokenInfo memory earnedData = StakedTokenInfo({
          tokenId:uint24(tokenId),
          earned:rewardmath,
          stakedAt:uint48(stakedAt)
        });
        infoArray[i]=earnedData;
    }
    return infoArray;
}


 
  // should never be used inside of transaction because of gas fee
  function balanceOf(address account) public view returns (uint256) {
    uint256 balance = 0;
    uint256 supply = nft.totalSupply();
    for(uint i = 1; i <= supply; i++) {
      if (vault[i].owner == account) {
        balance += 1;
      }
    }
    return balance;
  }

  // should never be used inside of transaction because of gas fee
  function tokensOfOwner(address account) public view returns (uint256[] memory ownerTokens) {

    uint256 supply = nft.totalSupply();
    uint256[] memory tmp = new uint256[](supply);

    uint256 index = 0;
    for(uint tokenId = 1; tokenId <= supply; tokenId++) {
      if (vault[tokenId].owner == account) {
        tmp[index] = vault[tokenId].tokenId;
        index +=1;
      }
    }

    uint256[] memory tokens = new uint256[](index);
    for(uint i = 0; i < index; i++) {
      tokens[i] = tmp[i];
    }

    return tokens;
  }


  
}