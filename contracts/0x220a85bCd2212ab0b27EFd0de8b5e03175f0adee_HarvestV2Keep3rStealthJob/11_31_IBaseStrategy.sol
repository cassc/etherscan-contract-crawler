// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBaseStrategy {
  // events
  event Harvested(uint256 _profit, uint256 _loss, uint256 _debtPayment, uint256 _debtOutstanding);

  // views

  function vault() external view returns (address _vault);

  function strategist() external view returns (address _strategist);

  function rewards() external view returns (address _rewards);

  function keeper() external view returns (address _keeper);

  function want() external view returns (address _want);

  function name() external view returns (string memory _name);

  function profitFactor() external view returns (uint256 _profitFactor);

  function maxReportDelay() external view returns (uint256 _maxReportDelay);

  function crv() external view returns (address _crv);

  // setters
  function setStrategist(address _strategist) external;

  function setKeeper(address _keeper) external;

  function setRewards(address _rewards) external;

  function tendTrigger(uint256 _callCost) external view returns (bool);

  function tend() external;

  function harvestTrigger(uint256 _callCost) external view returns (bool);

  function harvest() external;

  function setBorrowCollateralizationRatio(uint256 _c) external;
}