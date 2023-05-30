// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

interface IPresale {
  function buyTokens(address) view external returns (uint256);
}

contract PresaleClaim is Ownable {
  IERC20 kataToken;
  IPresale presale;

  mapping(address => uint256) public claimedTokens;

  uint256 public tgeAmount = 15;
  uint256 public tgeCliffTime = 1645617600;
  uint256 public tgeTime = 1640260800;
  uint256 public duration = 60 * 60 * 24 * 30 * 5;    // 5 months

  constructor(uint256 _tgeAmount, uint256 _tgeTime, uint256 _tgeCliffTime, uint256 _duration) {
    tgeAmount = _tgeAmount;
    tgeTime = _tgeTime;
    tgeCliffTime = _tgeCliffTime;
    duration = _duration;
  }

  function getClaimable(uint256 timestamp) public view returns(uint256) {
    uint256 buyTokens = presale.buyTokens(msg.sender);

    if (timestamp < tgeTime) return 0;
    if (timestamp < tgeCliffTime) {
      uint256 claimable = (buyTokens * tgeAmount) / 100;
      if (claimedTokens[msg.sender] > claimable) {
        return 0;
      }
      claimable = claimable - claimedTokens[msg.sender];
      return claimable;
    }
    if (buyTokens <= 0) return 0;
    if (buyTokens <= claimedTokens[msg.sender]) return 0;

    uint256 timeElapsed = timestamp - tgeCliffTime;

    if (timeElapsed > duration)
        timeElapsed = duration;

    uint256 _tge = 100 - tgeAmount;
    uint256 unlockedPercent = (10**6 * _tge * timeElapsed) / duration;
    unlockedPercent = unlockedPercent + tgeAmount * 10**6;

    uint256 unlockedAmount = (buyTokens * unlockedPercent) / (100 * 10**6);

    if (unlockedAmount < claimedTokens[msg.sender]) {
      return 0;
    }

    if (claimedTokens[msg.sender] > unlockedAmount) {
      return 0;
    } else {
      uint256 claimable = unlockedAmount - claimedTokens[msg.sender];

      return claimable;
    }
  }

  function claim() external {
    uint256 buyTokens = presale.buyTokens(msg.sender);

    require(buyTokens > 0, "No token purchased");
    require(buyTokens > claimedTokens[msg.sender], "You already claimed all");
    require(address(kataToken) != address(0), "Not initialised");

    uint256 claimable = getClaimable(block.timestamp);

    require (claimable > 0, "No token to claim");

    kataToken.transfer(msg.sender, claimable);

    claimedTokens[msg.sender] = claimedTokens[msg.sender] + claimable;
  }

  function setVesting(uint256 _tgeAmount, uint256 _tgeTime, uint256 _tgeCliffTime, uint256 _duration) external onlyOwner {
    tgeAmount = _tgeAmount;
    tgeTime = _tgeTime;
    tgeCliffTime = _tgeCliffTime;
    duration = _duration;
  }

  function setKataToken(address _kata) external onlyOwner {
    kataToken = IERC20(_kata);
  }

  function setPresale(address _presale) external onlyOwner {
    presale = IPresale(_presale);
  }
}