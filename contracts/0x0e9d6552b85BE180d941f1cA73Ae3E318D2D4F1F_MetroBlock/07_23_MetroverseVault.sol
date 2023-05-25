// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./MetroBlock.sol";
import "./MetToken.sol";


contract MetroverseVault is Ownable, IERC721Receiver {

  uint256 public totalStaked;
  
  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint24 tokenId;
    uint48 timestamp;
    address owner;
  }

  event BlockStaked(address owner, uint256 tokenId, uint256 value);
  event BlockUnstaked(address owner, uint256 tokenId, uint256 value);
  event Claimed(address owner, uint256 amount);

  // reference to the Block NFT contract
  MetroBlock nft;
  MetToken token;

  // maps tokenId to stake
  mapping(uint256 => Stake) public vault; 

  constructor(MetroBlock _nft, MetToken _token) { 
    nft = _nft;
    token = _token;
  }

  function stakeDuringMint(address account, uint256[] calldata tokenIds) external {
    require(msg.sender == address(nft), 'Can be called only by NFT contract');
    uint256 tokenId;
    totalStaked += tokenIds.length;
    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      require(nft.ownerOf(tokenId) == address(this), "nft must be sent first");
      require(vault[tokenId].tokenId == 0, 'already staked');

      vault[tokenId] = Stake({
        owner: account,
        tokenId: uint24(tokenId),
        timestamp: uint48(block.timestamp)
      });
      emit BlockStaked(account, tokenId, block.timestamp);
    }
  }

  function stake(uint256[] calldata tokenIds) external {
    uint256 tokenId;
    totalStaked += tokenIds.length;
    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      require(nft.ownerOf(tokenId) == msg.sender, "not your token");
      require(vault[tokenId].tokenId == 0, 'already staked');

      nft.transferFrom(msg.sender, address(this), tokenId);
      emit BlockStaked(msg.sender, tokenId, block.timestamp);

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
      emit BlockUnstaked(account, tokenId, block.timestamp);
      nft.transferFrom(address(this), account, tokenId);
    }
  }

  function claim(uint256[] calldata tokenIds) external {
      _claim(msg.sender, tokenIds, false);
  }

  function claimForAddress(address account, uint256[] calldata tokenIds) external {
      _claim(account, tokenIds, false);
  }

  function unstake(uint256[] calldata tokenIds) external {
      _claim(msg.sender, tokenIds, true);
  }

  function _claim(address account, uint256[] calldata tokenIds, bool _unstake) internal {
    uint256 tokenId;
    uint256 score;
    uint256 earned = 0;

    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];

      score = nft.getBlockScore(tokenId);

      Stake memory staked = vault[tokenId];
      require(staked.owner == account, "not an owner");

      uint256 stakedAt = staked.timestamp;
      earned += 1 ether * score * (block.timestamp - stakedAt) / 1 days;

      vault[tokenId] = Stake({
        owner: account,
        tokenId: uint24(tokenId),
        timestamp: uint48(block.timestamp)
      });

    }
    if (earned > 0) {
      uint256 boost = nft.getHoodBoost(tokenIds);
      earned = boost * earned / 10000;
      token.mint(account, earned);
    }
    if (_unstake) {
      _unstakeMany(account, tokenIds);
    }
    emit Claimed(account, earned);
  }

  function earningInfo(uint256[] calldata tokenIds) external view returns (uint256[2] memory info) {
     uint256 totalScore = 0;
     uint256 earned = 0;

     for (uint i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      uint256 score = nft.getBlockScore(tokenId);
      totalScore += score;

      Stake memory staked = vault[tokenId];

      uint256 stakedAt = staked.timestamp;

      earned += 1 ether * score * (block.timestamp - stakedAt) / 1 days;
    }

    uint256 boost = nft.getHoodBoost(tokenIds);
    earned = boost * earned / 10000;

    uint256 earnRatePerSecond = totalScore * 1 ether / 1 days;
    earnRatePerSecond = boost * earnRatePerSecond / 10000;

    // earned, earnRatePerSecond
    return [earned, earnRatePerSecond];
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

  function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "Cannot send nfts to Vault directly");
      return IERC721Receiver.onERC721Received.selector;
    }
  
}