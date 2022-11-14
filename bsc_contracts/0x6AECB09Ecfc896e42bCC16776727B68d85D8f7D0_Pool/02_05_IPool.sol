// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPool {
  event WithdrawInterest(address indexed user, uint256 value);
  event WithdrawInvest(address indexed user, address indexed referrer, uint256 value);
  event WithdrawToInvest(address indexed user, address indexed referrer, uint256 value);

  event UpdateUser(address indexed user, address indexed referrer, uint256 value);
  event RegisterUser(address indexed user, address indexed referrer, uint256 value);

  struct Invest {
    uint128 amount;
    uint128 startTime;
  }

  struct UserStruct {
    Invest[] invest;
    address referrer;
    uint8 percent;
    uint256 totalTree;
    uint256 latestWithdraw;
  }

  function BNBtoUSD(uint256 value) external view returns (uint256);

  function USDtoBNB(uint256 value) external view returns (uint256);

  function BNBPrice() external view returns (uint256);

  function BNBValue(address user) external view returns (uint256);

  function mining(address referrer) external payable;

  function withdrawInterest() external;

  function withdrawToInvest() external;

  function withdrawInvest(uint256 index) external;

  function totalInterest(address user) external view returns (uint256);

  function indexInterest(address sender, uint256 index)
    external
    view
    returns (uint256 day, uint256 intrest);

  function calculateInterest(address sender)
    external
    view
    returns (uint256[2][] memory rewards, uint256 timestamp);

  function changeUserPercent(address user, uint8 percent) external;

  function changeUserReferrer(address user, address referrer) external;

  function changeUserLatestWithdraw(address user, uint256 latestWithdraw) external;

  function changeUserInvest(
    address user,
    uint256 index,
    Invest memory invest
  ) external;

  function removeUserInvest(address user, uint256 index) external;

  function resetUser(address user) external;

  function userDepositNumber(address user) external view returns (uint256);

  function userTotalInvest(address user) external view returns (uint256);

  function userInvestDetails(address user) external view returns (Invest[] memory);

  function userDepositDetails(address user, uint256 index)
    external
    view
    returns (uint256 amount, uint256 startTime);

  function users(address user)
    external
    view
    returns (
      address referrer,
      uint8 percent,
      uint256 totalTree,
      uint256 latestWithdraw
    );
}