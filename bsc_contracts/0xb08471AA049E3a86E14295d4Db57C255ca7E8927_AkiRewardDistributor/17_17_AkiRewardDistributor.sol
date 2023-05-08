// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// import "hardhat/console.sol";

struct PaymentEnvelope {
  mapping(address => uint256) payeeToShares;
  uint256 totalShares;
  address nftAddress;
  IERC20 tokenAddress;
  uint256 amountRemains;
  uint256 rewardStartTime;
  uint256 rewardEndTime;
}

// function _burnIfLast(PaymentEnvelope[] storage array, uint32 index) {
//   array[index].amountRemains = 0;
//   array[index].totalShares = 0;

//   if (index == array.length -1) {
//     array.pop();
//   }
// }

contract AkiRewardDistributor is Ownable {
  mapping(string => mapping(address => uint64)) public campaignWinners;

  // delete _ideaPool[epochId];

  // function deleteCampaignWinners(
  //   string calldata campaignId,
  //   address[] calldata winners
  // ) public onlyOwner {
  //   for (uint32 i = 0; i < winners.length; i++) {
  //     delete campaignWinners[campaignId][winners[i]];
  //   }
  // }

  function setCampaignWinners(
    string calldata campaignId,
    address[] calldata winners
  ) public onlyOwner {
    for (uint32 i = 0; i < winners.length; i++) {
      campaignWinners[campaignId][winners[i]] = 1;
    }
  }

  function setCampaignWinners2(
    string calldata campaignId,
    bytes32[][] calldata winners
  ) public onlyOwner {
    // for (uint32 i = 0; i < winners.length; i++) {
    //   campaignWinners[campaignId][winners[i]] = 1;
    // }
  }

  // function getCampaignWinnersCount(
  //   string calldata campaignId
  // ) public view returns (uint32) {
  //   return campaignWinners[campaignId].length; 
  // }

  // function getCampaignsCount() public view returns (uint32) {
  //   return campaignWinners.length;
  // }
  
  function addPayment(
    IERC20 token,
    uint256 amount,
    address nftAddress,
    uint256 rewardStartTime,
    uint256 rewardEndTime
  ) public {
    // require(msg.sender == owner() || msg.sender == treasuryAddress_, "sender needs to be owner or treasury");
    // require(rewardEndTime > rewardStartTime, "Timestamp fails sanity check!");
    // require(address(token) != address(0), "Cannot be zero address!");
    // IERC721Enumerable enumerator = IERC721Enumerable(nftAddress);
    // uint256 totalTokens = enumerator.totalSupply();
    // IERC721 nft = IERC721(nftAddress);
    // require(nft.supportsInterface(type(IERC721Enumerable).interfaceId), "need to support the enumerable interface!");
    // SafeERC20.safeTransferFrom(token, msg.sender, address(this), amount);

    // uint256 envId = envelopes.length;
    // envelopes.push();
    // PaymentEnvelope storage env = envelopes[envId];
    // env.tokenAddress = token;
    // env.nftAddress = nftAddress;
    // env.amountRemains = amount;
    
    // mapping(address => uint64) storage levelInfo = nftToPayeeToShares[nftAddress];

    // for (uint64 idx = 0; idx < totalTokens; idx++) {
    //   uint256 tokenID = IERC721Enumerable(nftAddress).tokenByIndex(idx);
 
    //   address receiver = nft.ownerOf(tokenID);
    //   uint64 level = levelInfo[receiver];

    //   env.payeeToShares[receiver] += level;
    //   env.totalShares += level;
    //   env.rewardStartTime = rewardStartTime;
    //   env.rewardEndTime = rewardEndTime;
    //   // console.log(nftAddress);
    //   // console.log("add payment, shares %d", env.totalShares);
    // }
  }

  struct PaymentInfo {
    IERC20 tokenAddress;
    address nftAddress;
    uint256 share;
    uint256 totalShares;
    uint256 currentAmount;
  }

  function pullPaymentInfo() public view returns (PaymentInfo[] memory) {
    // address receiver = msg.sender;
    // PaymentInfo[] memory infos = new PaymentInfo[](envelopes.length);

    // for (uint64 i = 0; i < envelopes.length; i++) {
    //   PaymentEnvelope storage env = envelopes[i];
    //   uint256 share = env.payeeToShares[receiver];
    //   if (share == 0) {
    //     continue;
    //   }

    //   // console.log(block.timestamp, env.rewardStartTime, env.rewardEndTime);
    //   //if(!(block.timestamp > env.rewardStartTime && block.timestamp < env.rewardEndTime)) {
    //    // continue;
    //  // }
    //   uint256 currentAmount = share * env.amountRemains / env.totalShares;
    //   infos[i].currentAmount = currentAmount;
    //   infos[i].share = share;
    //   infos[i].totalShares = env.totalShares;
    //   infos[i].tokenAddress = env.tokenAddress;
    //   infos[i].nftAddress = env.nftAddress;
    // }
    // return infos;
  }

  function pullPayment() public {
    // address receiver = msg.sender;
    // PaymentInfo[] memory infos = pullPaymentInfo();
    // for (uint64 i = 0; i < envelopes.length; i++) {
    //   if (infos[i].currentAmount != 0) {
    //     PaymentEnvelope storage env = envelopes[i];
    //     PaymentInfo memory info = infos[i];
    //     uint256 currentAmount = info.share * env.amountRemains / env.totalShares;
    //     // console.log("shares", share, env.totalShares, env.amountRemains);

    //     env.totalShares -= info.share;
    //     env.amountRemains -= info.currentAmount;
    //     delete env.payeeToShares[receiver];
    //     SafeERC20.safeTransfer(env.tokenAddress, receiver, info.currentAmount);

    //   }
    // }
  }

  // function returnEnvelope() public onlyOwner {
  //   for (uint32 envIdx = 0; envIdx < envelopes.length; envIdx++) {
  //     PaymentEnvelope storage env = envelopes[envIdx];

  //     if (block.timestamp > env.rewardStartTime && block.timestamp < env.rewardEndTime) {
  //       continue;
  //     }
  //     // return to treasury
  //     SafeERC20.safeTransferFrom(env.tokenAddress, address(this), treasuryAddress_, env.amountRemains);
  //     _burnIfLast(envelopes, envIdx);
  //     // burn and return, as we don't want to handle looping array while burning
  //     return;
  //   }
  // }
}