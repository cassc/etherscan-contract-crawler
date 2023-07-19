// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPoolMaster {
  function manager() external view returns (address);

  function currency() external view returns (address);

  function borrows() external view returns (uint256);

  function insurance() external view returns (uint256);

  function reserves() external view returns (uint256);

  function getBorrowRate() external view returns (uint256);

  function getSupplyRate() external view returns (uint256);

  function poolSize() external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function getCurrentExchangeRate() external view returns (uint256);

  function rewardPerSecond() external view returns (uint256);

  function cash() external view returns (uint256);

  function interest() external view returns (uint256);

  function principal() external view returns (uint256);

  function decimals() external view returns (uint8);

  enum State {
    Active,
    Warning,
    ProvisionalDefault,
    Default,
    Closed
  }

  function state() external view returns (State);

  function initialize(address manager_, address currency_, bool requireKYC) external;

  function setRewardPerSecond(uint256 rewardPerSecond_) external;

  function withdrawReward(address account) external returns (uint256);

  function transferReserves() external;

  function processAuctionStart() external;

  function processDebtClaim() external;

  function setManager(address manager_) external;
}