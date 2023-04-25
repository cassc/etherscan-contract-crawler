// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

interface TruthGPT {
  function transfer(address to, uint256 amount) external returns (bool);

  function transferFrom(address from, address to, uint256 amount) external returns (bool);

  function balanceOf(address account) external view returns (uint256);
}

contract TruthGPTStake is ReentrancyGuard, Ownable {
  TruthGPT public truthGPT;

  struct Stake {
    uint256 amount;
    uint256 timestamp;
  }

  uint256 public arp = 750;
  uint256 public minStakingPeriod = 30 days;
  uint256 public withdrawPenalty = 25;

  mapping(address => Stake[]) private stakes;
  mapping(address => uint256) private stakingBalance;
  mapping(address => uint256) private lastClaimTime;

  event Staked(address indexed from, uint256 amount);
  event Unstaked(address indexed to, uint256 amount, uint256 stakingperiod);
  event Penalty(address indexed to, uint256 amount);
  event RewardClaimed(address indexed to, uint256 amount);

  constructor(address truthTokenAddress) Ownable() {
    truthGPT = TruthGPT(truthTokenAddress);
  }

  function setARP(uint256 _arp) external onlyOwner {
    require(_arp > 0, "Amount cann't be zero");
    arp = _arp;
  }

  function setMinStakingPeriod(uint256 _minStakingPeriod) external onlyOwner {
    require(_minStakingPeriod > 0, "Amount cann't be zero");
    minStakingPeriod = _minStakingPeriod;
  }

  function setWithdrawPenalty(uint256 _withdrawPenalty) external onlyOwner {
    require(_withdrawPenalty > 0, "Amount cann't be zero");
    withdrawPenalty = _withdrawPenalty;
  }

  function stakingbalance(address _staker) public view returns (uint256) {
    return stakingBalance[_staker];
  }

  function stakerdetails(address _staker, uint256 _index) public view returns (Stake memory) {
    return stakes[_staker][_index];
  }

  function lastclaimtime(address _staker) public view returns (uint256) {
    return lastClaimTime[_staker];
  }

  function allStaked(address _staker) public view returns (Stake[] memory) {
    return stakes[_staker];
  }

  function widthdrawTruth(address _address, uint256 _amount) public onlyOwner {
    truthGPT.transfer(_address, _amount);
  }

  function stake(uint256 _amount) public {
    require(_amount >= 1, "Amount can't be zero");
    require(truthGPT.balanceOf(msg.sender) >= _amount, 'Insufficient $TRUTH balance');

    truthGPT.transferFrom(msg.sender, address(this), _amount);
    stakingBalance[msg.sender] += _amount;
    stakes[msg.sender].push(Stake(_amount, block.timestamp));
    emit Staked(msg.sender, _amount);
  }

  function unstake(uint256 _index) public nonReentrant {
    require(stakes[msg.sender].length > 0, 'No stakes found for the address');
    require(stakes[msg.sender].length >= _index + 1, 'Stake does not exist');
    // uint256 totalStaked = stakingBalance[msg.sender];
    uint256 lastStakeIndex = _index;
    Stake memory lastStake = stakes[msg.sender][lastStakeIndex];
    uint256 timeStaked = block.timestamp - lastStake.timestamp;
    require(timeStaked >= minStakingPeriod, 'Minimum staking period not reached');
    uint256 latestStake = lastStake.amount;
    uint256 reward = (latestStake * arp) / 10000;
    uint256 payout = latestStake + reward;
    // Remove the stake at the given index
    for (uint256 i = _index; i < stakes[msg.sender].length - 1; i++) {
      stakes[msg.sender][i] = stakes[msg.sender][i + 1];
    }
    stakes[msg.sender].pop();
    stakingBalance[msg.sender] -= latestStake;
    lastClaimTime[msg.sender] = block.timestamp;
    truthGPT.transfer(msg.sender, payout);
    emit Unstaked(msg.sender, payout, timeStaked);
  }

  function withdrawpenalty(uint256 _index) public nonReentrant {
    require(stakes[msg.sender].length > 0, 'No stakes found for the address');
    require(stakes[msg.sender].length >= _index + 1, 'Stake does not exist');
    uint256 lastStakeIndex = _index;
    Stake memory lastStake = stakes[msg.sender][lastStakeIndex];
    uint256 timeStaked = block.timestamp - lastStake.timestamp;
    uint256 latestStake = lastStake.amount;
    require(timeStaked <= minStakingPeriod, 'Withdraw with penalty time exceed you can now unstake token ');
    uint256 penalty = (latestStake * withdrawPenalty) / 100;
    // Remove the stake at the given index
    for (uint256 i = _index; i < stakes[msg.sender].length - 1; i++) {
      stakes[msg.sender][i] = stakes[msg.sender][i + 1];
    }
    stakes[msg.sender].pop();
    stakingBalance[msg.sender] -= latestStake;
    lastClaimTime[msg.sender] = block.timestamp;
    uint256 payout = latestStake - penalty;
    truthGPT.transfer(msg.sender, payout);
    emit Penalty(msg.sender, payout);
  }

  function claimReward() public nonReentrant {
    require(stakes[msg.sender].length > 0, 'No stakes found for the address');
    uint256 totalStaked = stakingBalance[msg.sender];
    uint256 lastClaim = lastClaimTime[msg.sender];
    uint256 timeElapsed = block.timestamp - lastClaim;
    require(timeElapsed > 0, 'No rewards to claim');
    uint256 reward = (totalStaked * (arp / 365) * (timeElapsed / 1 days)) / 100;
    require(reward > 0, 'Not Eligible for reward');
    lastClaimTime[msg.sender] = block.timestamp;
    truthGPT.transfer(msg.sender, reward);
    emit RewardClaimed(msg.sender, reward);
  }
}