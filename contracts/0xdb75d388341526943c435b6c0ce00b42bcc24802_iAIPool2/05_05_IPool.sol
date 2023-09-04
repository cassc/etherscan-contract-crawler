// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

interface IiAI {
  function transfer(address to, uint256 amount) external returns (bool);

  function transferFrom(address from, address to, uint256 amount) external returns (bool);

  function balanceOf(address account) external view returns (uint256);
}

interface I9022 {
  function balanceOf(address account) external view returns (uint256);

  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}

contract IPool is ReentrancyGuard, Ownable {
  IiAI public iAI;
  I9022 public nft9022;

  struct Pool {
    uint256 amount;
    uint256 apr;
    uint256 timestamp;
    string poolType;
  }

  string public poolType;
  uint256 public apr;
  uint256 public nftThreshold;
  uint256 public tokenThreshold;
  uint256 public minPoolPeriod;
  uint256 public withdrawPenalty = 25;
  bool public poolActive = true;

  mapping(address => Pool[]) internal poolData;
  mapping(address => uint256) internal poolBalance;
  mapping(address => uint256) internal lastClaimTime;

  event Pooled(address indexed from, uint256 amount);
  event Unpooled(address indexed to, uint256 amount, uint256 poolPeriod);
  event Penalty(address indexed to, uint256 amount);
  event RewardClaimed(address indexed to, uint256 amount);
  event Received(address, uint);

  constructor(address iAITokenAddress, address nftTokenAddress) Ownable() {
    iAI = IiAI(iAITokenAddress);
    nft9022 = I9022(nftTokenAddress);
  }

  receive() external payable {
    emit Received(msg.sender, msg.value);
  }

  function setPoolState() external onlyOwner {
    poolActive = !poolActive;
  }

  function setIAIToken(address _tokenAddress) external onlyOwner {
    iAI = IiAI(_tokenAddress);
  }

  function setNftToken(address _tokenAddress) external onlyOwner {
    nft9022 = I9022(_tokenAddress);
  }

  function setTokenThreshold(uint256 _amount) external onlyOwner {
    require(_amount > 0, 'Amount can not be 0');
    tokenThreshold = _amount;
  }

  function setNftThreshold(uint256 _amount) external onlyOwner {
    require(_amount > 0, 'Amount can not be 0');
    nftThreshold = _amount;
  }

  function setARP(uint256 _arp) external onlyOwner {
    require(_arp > 0, 'Amount can not be zero');
    apr = _arp;
  }

  function setMinPoolingPeriod(uint256 _minstakingPeriod) external onlyOwner {
    require(_minstakingPeriod > 0, "Amount cann't be zero");
    minPoolPeriod = _minstakingPeriod;
  }

  function setWithdrawPenalty(uint256 _withdrawPenalty) external onlyOwner {
    require(_withdrawPenalty > 0, "Amount cann't be zero");
    withdrawPenalty = _withdrawPenalty;
  }

  function poolPostions(address _staker) public view returns (uint256) {
    return poolBalance[_staker];
  }

  function poolPostionDetails(address _staker, uint256 _index) public view returns (Pool memory) {
    return poolData[_staker][_index];
  }

  function lastclaimtime(address _staker) public view returns (uint256) {
    return lastClaimTime[_staker];
  }

  function allPooled(address _staker) public view returns (Pool[] memory) {
    return poolData[_staker];
  }

  function widthdrawIAI(address _address, uint256 _amount) external onlyOwner {
    iAI.transfer(_address, _amount);
  }

  function withdraw(address _address) external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, 'Amount is too high');
    payable(_address).transfer(balance);
  }

  function getUserTokens(address _address) public view returns (uint256[] memory) {
    uint256 totalTokens = nft9022.balanceOf(_address);
    uint256[] memory tokenIds = new uint256[](totalTokens);

    for (uint256 i = 0; i < totalTokens; i++) {
      tokenIds[i] = nft9022.tokenOfOwnerByIndex(_address, i);
    }

    return tokenIds;
  }
}