// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IUserData {
  event Register(address indexed user, address indexed ref, uint256 indexed gift);
  event Investment(address indexed user, uint256 value);
  event GiftReceived(address indexed user, uint256 value);
  event ReferralReceived(address indexed user, address from, uint256 value);

  struct Invest {
    uint64 amount;
    uint64 period;
    uint64 reward;
    uint64 startTime;
  }

  struct UserStruct {
    Invest[] invest;
    address referrer;
    uint64 refAmount;
    uint64 giftAmount;
    uint64 latestWithdraw;
  }

  // Registeration functions ----------------------------------------------------------
  function registerAndInvest(
    address user,
    address referrer,
    uint256 gift,
    Invest memory invest
  ) external returns (bool);

  function register(
    address user,
    address referrer,
    uint256 gift
  ) external returns (bool);

  function investment(address user, Invest memory invest) external returns (bool);

  function payReferrer(
    address lastRef,
    uint64 value,
    uint8 level
  ) external returns (bool);

  // Modifier functions ----------------------------------------------------------
  function changeInvestIndex(
    address user,
    uint256 index,
    Invest memory invest
  ) external returns (bool);

  function changeInvestIndexReward(
    address user,
    uint256 index,
    uint256 value
  ) external returns (bool);

  function changeUserData(
    address user,
    uint256 ref,
    uint256 gift,
    uint256 lw
  ) external returns (bool);

  function resetAfterWithdraw(address user) external returns (bool);

  function changeLatestWithdraw(address user, uint256 latestWithdraw) external;

  function changeReferrer(address user, address referrer) external;

  function changeGiftAmount(address user, uint256 value) external;

  function changeRefAmount(address user, uint256 value) external;

  function addGiftAmount(address user, uint256 value) external;

  function addRefAmount(address user, uint256 value) external;

  function deleteUserInvestIndex(address user, uint256 index) external;

  function deleteUserInvest(address user) external;

  function deleteUser(address user) external;

  // User Details ----------------------------------------------------------
  function users(address user)
    external
    view
    returns (
      address referrer,
      uint64 refAmount,
      uint64 giftAmount,
      uint64 latestWithdraw
    );

  function calculateHourly(address user, uint256 time)
    external
    view
    returns (uint256 rewards);

  function exist(address user) external view returns (bool);

  function referrer(address user) external view returns (address);

  function latestWithdraw(address user) external view returns (uint256);

  function depositNumber(address user) external view returns (uint256);

  function investDetails(address user) external view returns (Invest[] memory);

  function depositDetail(address user, uint256 index)
    external
    view
    returns (
      uint256 amount,
      uint256 period,
      uint256 reward,
      uint256 startTime,
      uint256 endTime
    );

  function maxPeriod(address user) external view returns (uint256);

  function investExpireTime(address user, uint256 index) external view returns (uint256);

  function investIsExpired(address user, uint256 index) external view returns (bool);

  function notBlacklisted(address user) external view returns (bool);
}