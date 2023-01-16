// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface IStaking {
  struct Multiplier {
    string name;
    address contractAdd;
    bool active;
    uint16 multi;
    uint128 start;
    uint128 end;
  }

  struct User {
    uint256 totalInvested;
    uint256 totalWithdrawn;
    uint32 lastPayout;
    uint32 depositTime;
    uint256 totalClaimed;
  }

  struct Pool {
    bool isWithdrawLocked;
    uint128 rewardRate;
    uint16 lockPeriodInDays;
    uint32 totalInvestors;
    uint32 startDate;
    uint32 endDate;
    uint256 totalInvested;
    uint256 hardCap;
    address input;
    address reward;
  }

  event Claim(uint16 pid, address indexed addr, uint256 amount, uint256 time);

  function setMultiplier(
    uint16 _pid,
    string calldata _name,
    address _contractAdd,
    bool _isUsed,
    uint16 _multiplier,
    uint128 _startIdx,
    uint128 _endIdx
  ) external;

  function add(
    bool _isWithdrawLocked,
    uint128 _rewardRate,
    uint16 _lockPeriodInDays,
    uint32 _endDate,
    uint256 _hardCap,
    address _inputToken,
    address _rewardToken
  ) external;

  function set(
    uint16 _pid,
    bool _isWithdrawLocked,
    uint128 _rewardRate,
    uint16 _lockPeriodInDays,
    uint32 _endDate,
    uint256 _hardCap,
    address _inputToken,
    address _rewardToken
  ) external;

  function claim(uint16 _pid) external returns (bool);

  function claimAll() external returns (bool);

  function transferStuckNFT(address _nft, uint256 _id) external returns (bool);

  function transferStuckToken(address _token) external returns (bool);

  function canClaim(uint16 _pid, address _addr) external view returns (bool);

  function calcMultiplier(uint16 _pid, address _addr) external view returns (uint16);

  function ownsCorrectMulti(uint16 _pid, address _addr) external view returns (bool);

  function poolLength() external view returns (uint256);

  function payout(uint16 _pid, address _addr) external view returns (uint256 value);
}