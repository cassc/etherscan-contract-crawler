// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface IDecubateMasterChef {
  struct NFTMultiplier {
    bool active;
    string name;
    address contractAdd;
    uint16 multiplier;
    uint16 startIdx;
    uint16 endIdx;
  }

  /**
   *
   * @dev User reflects the info of each user
   *
   *
   * @param {totalInvested} how many tokens the user staked
   * @param {totalWithdrawn} how many tokens withdrawn so far
   * @param {lastPayout} time at which last claim was done
   * @param {depositTime} Time of last deposit
   * @param {totalClaimed} Total claimed by the user
   *
   */
  struct User {
    uint256 totalInvested;
    uint256 totalWithdrawn;
    uint256 lastPayout;
    uint256 depositTime;
    uint256 totalClaimed;
  }

  function add(
    uint256 _apy,
    uint256 _lockPeriodInDays,
    uint256 _endDate,
    uint256 _hardCap,
    address token
  ) external;

  function set(
    uint256 _pid,
    uint256 _apy,
    uint256 _lockPeriodInDays,
    uint256 _endDate,
    uint256 _hardCap,
    uint256 _maxTransfer,
    address token
  ) external;

  function setNFT(
    uint256 _pid,
    string calldata _name,
    address _contractAdd,
    bool _isUsed,
    uint16 _multiplier,
    uint16 _startIdx,
    uint16 _endIdx
  ) external;

  function stake(uint256 _pid, uint256 _amount) external returns (bool);

  function claim(uint256 _pid) external returns (bool);

  function reinvest(uint256 _pid) external returns (bool);

  function reinvestAll() external returns (bool);

  function claimAll() external returns (bool);

  function handleNFTMultiplier(
    uint256 _pid,
    address _user,
    uint256 _rewardAmount
  ) external returns (uint256);

  function unStake(uint256 _pid, uint256 _amount) external returns (bool);

  function updateCompounder(address _compounder) external;

  function canClaim(uint256 _pid, address _addr) external view returns (bool);

  function calcMultiplier(uint256 _pid, address _addr) external view returns (uint16);

  function payout(uint256 _pid, address _addr) external view returns (uint256 value);

  function poolInfo(uint256)
    external
    view
    returns (
      uint256 apy,
      uint256 lockPeriodInDays,
      uint256 totalDeposit,
      uint256 startDate,
      uint256 endDate,
      uint256 hardCap,
      address token
    );

  function users(uint256, address)
    external
    view
    returns (
      uint256 totalInvested,
      uint256 totalWithdrawn,
      uint256 lastPayout,
      uint256 depositTime,
      uint256 totalClaimed
    );

  function poolLength() external view returns (uint256);
}