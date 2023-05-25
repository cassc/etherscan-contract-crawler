// SPDX-License-Identifier: MIT LICENSE
// Developed by Thanic® Tech Labs

pragma solidity 0.8.9;

import "./StoneParticles.sol";
import "../KahiruMK.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NFTStaking is Ownable, IERC721Receiver {

  uint256 public totalStaked;


  
  struct Stake {
    uint24 tokenId;
    uint48 timestamp;
    uint256 cycles;
    address owner;
    uint8 rarity;
  }

  event NFTStaked(address owner, uint256 tokenId, uint256 value);
  event NFTUnstaked(address owner, uint256 tokenId, uint256 value);
  event Claimed(address owner, uint256 amount);

  KahiruF nft;
  StoneParticles token;

  mapping(uint256 => Stake) public vault;
  mapping(bytes => bool) public signatureUsed;

   constructor(KahiruF _nft, StoneParticles _token) { 
    nft = _nft;
    token = _token;
  }

  function stake(uint256[] calldata tokenIds,uint8[] calldata rarity, bytes32 hash, bytes memory signature) external {
    require(recoverSigner(hash, signature), "Sign not valid");
    require(!signatureUsed[signature], "Signature has already been used.");
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
        cycles: 0,
        timestamp: uint48(block.timestamp),
        rarity: rarity[i]
      });
    }
    signatureUsed[signature] = true;
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

  function claimForAddress(address account, uint256[] calldata tokenIds) external {
      _claim(account, tokenIds, false);
  }

  function unstake(uint256[] calldata tokenIds) external {
      _claim(msg.sender, tokenIds, true);
  }

  function _claim(address account, uint256[] calldata tokenIds, bool _unstake) internal{
     uint256 tokenId;
     uint256 earned = 0;
     uint256 withdraw = 0;
     uint256 _cycles = 0;
     uint256 bonus = 0;
     uint256 ammount = 0;
     uint256 rarityrewards = 0; 


    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      Stake memory staked = vault[tokenId];
      require(staked.owner == account, "not an owner");
      uint256 stakedAt = staked.timestamp; 
      _cycles = ((block.timestamp - stakedAt) / 86400);
      staked.cycles = _cycles;
      ammount = 7 * _cycles;
      rarityrewards = _cycles/7;
      if (staked.rarity == 0){
        bonus = 2 * rarityrewards;
      }
      if (staked.rarity == 1){
        bonus = 5 * rarityrewards;
      }
      if (staked.rarity == 2){
        bonus = 15 * rarityrewards;
      }
      withdraw = withdraw + ammount + bonus;
    }
    earned = withdraw * (1 ether);
    if (earned > 0) {
      token.mint(account, earned);
    }
    if (_unstake) {
      _unstakeMany(account, tokenIds);
    }
    emit Claimed(account, earned);
  }

  function earningInfo(address account, uint256[] calldata tokenIds) external view returns (uint256[1] memory info, uint256 cycles, uint256 total) {
     uint256 tokenId;
     uint256 earned = 0;
     uint256 withdraw = 0;
     uint256 _cycles = 0;
     uint256 bonus = 0;
     uint256 ammount = 0;
     uint256 rarityrewards = 0; 

    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      Stake memory staked = vault[tokenId];
      require(staked.owner == account, "not an owner");
      uint256 stakedAt = staked.timestamp; 
      _cycles = ((block.timestamp - stakedAt) / 86400);
      staked.cycles = _cycles;
      ammount = 7 * _cycles;
      rarityrewards = _cycles/7;
      if (staked.rarity == 0){
        bonus = 2 * rarityrewards;
      }
      if (staked.rarity == 1){
        bonus = 5 * rarityrewards;
      }
      if (staked.rarity == 2){
        bonus = 15 * rarityrewards;
      }
      withdraw = withdraw + ammount + bonus;
    }
    earned = withdraw * (1 ether);

    if (earned > 0) {
      return ([earned],_cycles, bonus);
    }
}

  function balanceOf(address account) public view returns (uint256) {
    uint256 balance = 0;
    uint256 supply = nft.totalSupply();
    for(uint i = 0; i <= supply; i++) {
      if (vault[i].owner == account) {
        balance += 1;
      }
    }
    return balance;
  }


  function tokensOfOwner(address account) public view returns (uint256[] memory ownerTokens) {

    uint256 supply = nft.totalSupply();
    uint256[] memory tmp = new uint256[](supply);

    uint256 index = 0;
    for(uint tokenId = 0; tokenId <= supply; tokenId++) {
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

  function recoverSigner(bytes32 hash, bytes memory signature) private pure returns (bool) {
    bytes32 messageDigest = keccak256(
        abi.encodePacked(
            "\x19Ethereum Signed Message:\n32", 
            hash
        )
    );
    if (ECDSA.recover(messageDigest, signature) == 0x0aC6119362e892aeA0025BF00182CaD3673A9c79){
      return true;
    }
    else{
      return false;
    }
}

  function divide(uint256 uno) public pure returns (uint256) {

        uint division = uno / 20;
        return division;
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