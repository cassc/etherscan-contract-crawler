// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IKeep3rLiquidityManagerJobHandler {
  function job() external view returns (address _job);

  function setJob(address _job) external;
}

abstract contract Keep3rLiquidityManagerJobHandler is IKeep3rLiquidityManagerJobHandler {
  address public override job;

  function _setJob(address _job) internal {
    job = _job;
  }

  modifier onlyJob() {
    require(msg.sender == job, 'Keep3rLiquidityManagerJobHandler::unauthorized-job');
    _;
  }
}