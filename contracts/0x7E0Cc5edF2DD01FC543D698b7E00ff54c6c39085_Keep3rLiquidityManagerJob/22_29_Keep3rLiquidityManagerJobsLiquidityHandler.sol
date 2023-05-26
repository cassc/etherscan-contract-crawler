// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/EnumerableSet.sol';

interface IKeep3rLiquidityManagerJobsLiquidityHandler {
  event JobAdded(address _job);

  event JobRemoved(address _job);

  function jobs() external view returns (address[] memory _jobsList);

  function jobLiquidities(address _job) external view returns (address[] memory _liquiditiesList);

  function jobLiquidityDesiredAmount(address _job, address _liquidity) external view returns (uint256 _amount);
}

abstract contract Keep3rLiquidityManagerJobsLiquidityHandler is IKeep3rLiquidityManagerJobsLiquidityHandler {
  using SafeMath for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;

  // job[]
  EnumerableSet.AddressSet internal _jobs;
  // job => lp[]
  mapping(address => EnumerableSet.AddressSet) internal _jobLiquidities;
  // job => lp => amount
  mapping(address => mapping(address => uint256)) public override jobLiquidityDesiredAmount;

  function jobs() public view override returns (address[] memory _jobsList) {
    _jobsList = new address[](_jobs.length());
    for (uint256 i; i < _jobs.length(); i++) {
      _jobsList[i] = _jobs.at(i);
    }
  }

  function jobLiquidities(address _job) public view override returns (address[] memory _liquiditiesList) {
    _liquiditiesList = new address[](_jobLiquidities[_job].length());
    for (uint256 i; i < _jobLiquidities[_job].length(); i++) {
      _liquiditiesList[i] = _jobLiquidities[_job].at(i);
    }
  }

  function _addJob(address _job) internal {
    if (_jobs.add(_job)) emit JobAdded(_job);
  }

  function _removeJob(address _job) internal {
    if (_jobs.remove(_job)) emit JobRemoved(_job);
  }

  function _addLPToJob(address _job, address _liquidity) internal {
    _jobLiquidities[_job].add(_liquidity);
    if (_jobLiquidities[_job].length() == 1) _addJob(_job);
  }

  function _removeLPFromJob(address _job, address _liquidity) internal {
    _jobLiquidities[_job].remove(_liquidity);
    if (_jobLiquidities[_job].length() == 0) _removeJob(_job);
  }
}