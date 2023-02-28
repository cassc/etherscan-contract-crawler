// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUsers {
  event WithdrawIndexInterest(address indexed user, uint256 indexed index, uint256 value);
  event WithdrawInterest(address indexed user, uint256 value, uint256 refReward);

  event WithdrawInvest(address indexed user, address indexed referrer, uint256 value);

  event WithdrawToInvest(
    address indexed user,
    address indexed referrer,
    uint256 value,
    uint256 hourly
  );

  event UpdateUser(
    address indexed user,
    address indexed referrer,
    uint256 value,
    uint256 hourly
  );

  event RegisterUser(
    address indexed user,
    address indexed referrer,
    uint256 value,
    uint256 hourly
  );

  event RewardRecieved(address indexed user, uint256 value);
  event GiftRecieved(address indexed user, uint256 value);

  event UpdateUserToken(address indexed user, address indexed referrer, uint256 value);
  event RegisterUserToken(address indexed user, address indexed referrer, uint256 value);

  struct Interest {
    uint256 amount;
    uint256 time;
  }

  struct Invest {
    uint64 amount;
    uint64 hourly;
    uint64 startTime;
    uint64 latestWithdraw;
  }

  struct UserStruct {
    address referrer;
    bool isTokenMode;
    bool isInterestMode;
    bool isBlackListed;
    uint8 percent;
    uint64 refReward;
    uint256 levelOneTotal;
    Invest[] invest;
  }

  function BNBtoUSD(uint256 value) external view returns (uint256);

  function USDtoBNB(uint256 value) external view returns (uint256);

  function BNBPrice() external view returns (uint256);

  function TokenToUSD(uint256 value) external view returns (uint256);

  function USDtoToken(uint256 value) external view returns (uint256);

  function TokenPrice() external view returns (uint256);

  function BNBValue(address user) external view returns (uint256);

  function TokenValue(address user) external view returns (uint256);

  function stake(address referrer, bool isMonthly) external payable;

  function stakeToken(address referrer, uint256 amount) external;

  function withdrawInterest() external;

  function withdrawToInvest(bool isMonthly) external;

  function withdrawInvest(uint256 index) external;

  function intoTokenMode() external payable;

  function intoMonthlyInvest(uint256 index) external;

  function userInvestDetails(address user)
    external
    view
    returns (Invest[] memory invest, uint256 total);

  function userInterestDetails(address sender, uint256 requestTime)
    external
    view
    returns (Interest[] memory interest, uint256 total);

  function userDepositNumber(address user) external view returns (uint256);

  function userDepositDetails(address user, uint256 index)
    external
    view
    returns (Invest memory);

  function users(address user)
    external
    view
    returns (
      address referrer,
      bool isTokenMode,
      bool isInterestMode,
      bool isBlackListed,
      uint8 percent,
      uint64 refReward,
      uint256 levelOneTotal
    );
}