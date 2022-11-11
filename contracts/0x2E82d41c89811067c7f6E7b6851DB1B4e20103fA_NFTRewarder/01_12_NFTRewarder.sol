// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./IRewarder.sol";
import "./BoringMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTRewarder is Ownable, IRewarder {
  using BoringMath for uint256;
  using SafeERC20 for IERC20;

  event NFTReward(uint256 pid, address user, address recipient, uint256 zeroxzeroAmount, uint256 newLpAmount);

  address public STAKING; // Contract that is allowed to call into the rewarder
  uint256 public MULTIPLIER; // Percentage of staking reward paid as a bonus
  IERC721 public NFT_CONTRACT; // NFT that must be owned for bonus
  IERC20 public REWARD; // ERC20 paid out as reward

  constructor (address nftContract, uint256 multiplier) {
    NFT_CONTRACT = IERC721(nftContract);
    MULTIPLIER = multiplier;
  }

  function setStaking(address zeroxzeroStaking) onlyOwner external {
    STAKING = zeroxzeroStaking;
  }

  function setMultiplier(uint256 multiplier) onlyOwner external {
    MULTIPLIER = multiplier;
  }

  function setNFT(address nftContract) onlyOwner external {
    NFT_CONTRACT = IERC721(nftContract);
  }

  function setReward(address reward) onlyOwner external {
    REWARD = IERC20(reward);
  }

  function onZeroxZeroReward(uint256 pid, address user, address recipient, uint256 zeroxzeroAmount, uint256 newLpAmount) override external {
    require(msg.sender == STAKING, "Can only be called from 0x0 Staking contract");
    // We will reward staker with an additional multiplier * zeroxzeroAmount if they hold an NFT from NFT_CONTRACT
    uint256 nftBalance = NFT_CONTRACT.balanceOf(user);
    if (nftBalance > 10) nftBalance = 10; //Maximum reward is 100%
    if ((address(REWARD) != address(0)) && (nftBalance > 0)) {
      uint256 rewardAmount = zeroxzeroAmount.mul(MULTIPLIER.mul(nftBalance)) / 100;
      uint256 rewardBalance = REWARD.balanceOf(address(this));
      if (rewardAmount > rewardBalance) {
        rewardAmount = rewardBalance;
      }
      REWARD.safeTransfer(recipient, rewardAmount);
      emit NFTReward(pid, user, recipient, rewardAmount, newLpAmount);
    }
  }
}