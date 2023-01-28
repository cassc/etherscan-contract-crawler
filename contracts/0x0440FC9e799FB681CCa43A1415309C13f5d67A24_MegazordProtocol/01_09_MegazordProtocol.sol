// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MegazordProtocol is ReentrancyGuard, Ownable {
  // Interface for ERC721
  IERC721 public immutable nftCollection;

  struct StakedToken {
    address staker;
    uint256 tokenId;
  }

  // Staker info
  struct Staker {
    // Amount of tokens staked by the staker
    uint256 amountStaked;
    // Last time of the rewards were calculated for this user
    uint256 timeOfLastUpdate;
    // Staked token ids
    StakedToken[] stakedTokens;
  }

  // Mapping of User Address to Staker info
  mapping(address => Staker) public stakers;

  // Mapping of Token Id to staker. Made for the SC to remeber
  // who to send back the ERC721 Token to.
  mapping(uint256 => address) public stakerAddress;

  // Constructor function to set the rewards token and the NFT collection addresses
  constructor(IERC721 _nftCollection) {
    nftCollection = _nftCollection;
  }

  // If address already has ERC721 Token/s staked, calculate the rewards.
  // Increment the amountStaked and map msg.sender to the Token Id of the staked
  // Token to later send back on withdrawal. Finally give timeOfLastUpdate the
  // value of now.
  function stake(uint256[] calldata _tokenIds) external nonReentrant {
    require(
      stakers[msg.sender].amountStaked < 25,
      "You already staked 25 nfts"
    );
    // Wallet must own the token they are trying to stake
    require(
      nftCollection.ownerOf(_tokenIds[0]) == _msgSender(),
      "You don't own this token!"
    );

    //require(_tokenIds.length == 25, "Megazord requires 25 nfts selected");
    // require(
    //   nftCollection.isApprovedForAll(address(this), _msgSender()),
    //   "You didn't approve the Megazord contract to transfer nfts for you"
    // );

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      // Transfer all the tokens from the wallet to the Smart contract
      nftCollection.transferFrom(msg.sender, address(this), _tokenIds[i]);
    }

    // Increment the amount staked for this wallet
    stakers[msg.sender].amountStaked++;

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      // Update the mapping of the tokenId to the staker's address
      stakerAddress[_tokenIds[i]] = msg.sender;
    }

    // Update the timeOfLastUpdate for the staker
    stakers[msg.sender].timeOfLastUpdate = block.timestamp;
  }

  // Check if user has any ERC721 Tokens Staked and if they tried to withdraw,
  // calculate the rewards and store them in the unclaimedRewards
  // decrement the amountStaked of the user and transfer the ERC721 token back to them
  function withdraw(uint256[] calldata _tokenIds) external onlyOwner {
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      // Update the mapping of the tokenId to the be address(0) to indicate that the token is no longer staked
      stakerAddress[_tokenIds[i]] = address(0);
      // Transfer the token back to the withdrawer
      nftCollection.transferFrom(address(this), msg.sender, _tokenIds[i]);
    }

    // Update the timeOfLastUpdate for the withdrawer
    stakers[msg.sender].timeOfLastUpdate = block.timestamp;
  }
}