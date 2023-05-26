// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './Keep3rLiquidityManagerEscrowsHandler.sol';
import './Keep3rLiquidityManagerUserLiquidityHandler.sol';
import './Keep3rLiquidityManagerJobsLiquidityHandler.sol';

interface IKeep3rLiquidityManagerUserJobsLiquidityHandler {
  event LiquidityMinSet(address _liquidity, uint256 _minAmount);
  event LiquidityOfJobSet(address indexed _user, address _liquidity, address _job, uint256 _amount);
  event IdleLiquidityRemovedFromJob(address indexed _user, address _liquidity, address _job, uint256 _amount);

  function liquidityMinAmount(address _liquidity) external view returns (uint256 _minAmount);

  function userJobLiquidityAmount(
    address _user,
    address _job,
    address _liquidity
  ) external view returns (uint256 _amount);

  function userJobLiquidityLockedAmount(
    address _user,
    address _job,
    address _liquidity
  ) external view returns (uint256 _amount);

  function userJobCycle(address _user, address _job) external view returns (uint256 _cycle);

  function jobCycle(address _job) external view returns (uint256 _cycle);

  function setMinAmount(address _liquidity, uint256 _minAmount) external;

  function setJobLiquidityAmount(
    address _liquidity,
    address _job,
    uint256 _amount
  ) external;

  function forceRemoveLiquidityOfUserFromJob(
    address _user,
    address _liquidity,
    address _job
  ) external;

  function removeIdleLiquidityFromJob(
    address _liquidity,
    address _job,
    uint256 _amount
  ) external;
}

abstract contract Keep3rLiquidityManagerUserJobsLiquidityHandler is
  Keep3rLiquidityManagerEscrowsHandler,
  Keep3rLiquidityManagerUserLiquidityHandler,
  Keep3rLiquidityManagerJobsLiquidityHandler,
  IKeep3rLiquidityManagerUserJobsLiquidityHandler
{
  using SafeMath for uint256;

  // lp => minAmount
  mapping(address => uint256) public override liquidityMinAmount;
  // user => job => lp => amount
  mapping(address => mapping(address => mapping(address => uint256))) public override userJobLiquidityAmount;
  // user => job => lp => amount
  mapping(address => mapping(address => mapping(address => uint256))) public override userJobLiquidityLockedAmount;
  // user => job => cycle
  mapping(address => mapping(address => uint256)) public override userJobCycle;
  // job => cycle
  mapping(address => uint256) public override jobCycle;

  function _setMinAmount(address _liquidity, uint256 _minAmount) internal {
    liquidityMinAmount[_liquidity] = _minAmount;
    emit LiquidityMinSet(_liquidity, _minAmount);
  }

  function setJobLiquidityAmount(
    address _liquidity,
    address _job,
    uint256 _amount
  ) external virtual override {
    _setLiquidityToJobOfUser(msg.sender, _liquidity, _job, _amount);
  }

  function removeIdleLiquidityFromJob(
    address _liquidity,
    address _job,
    uint256 _amount
  ) external virtual override {
    _removeIdleLiquidityOfUserFromJob(msg.sender, _liquidity, _job, _amount);
  }

  function _setLiquidityToJobOfUser(
    address _user,
    address _liquidity,
    address _job,
    uint256 _amount
  ) internal {
    _amount = _amount.div(2).mul(2); // removes potential decimal dust

    require(_amount != userJobLiquidityAmount[_user][_job][_liquidity], 'Keep3rLiquidityManager::same-liquidity-amount');

    userJobCycle[_user][_job] = jobCycle[_job];

    if (_amount > userJobLiquidityLockedAmount[_user][_job][_liquidity]) {
      _addLiquidityOfUserToJob(_user, _liquidity, _job, _amount.sub(userJobLiquidityAmount[_user][_job][_liquidity]));
    } else {
      _subLiquidityOfUserFromJob(_user, _liquidity, _job, userJobLiquidityAmount[_user][_job][_liquidity].sub(_amount));
    }
    emit LiquidityOfJobSet(_user, _liquidity, _job, _amount);
  }

  function _forceRemoveLiquidityOfUserFromJob(
    address _user,
    address _liquidity,
    address _job
  ) internal {
    require(!IKeep3rV1(keep3rV1).jobs(_job), 'Keep3rLiquidityManager::force-remove-liquidity:job-on-keep3r');
    // set liquidity as 0 to force exit on stuck job
    _setLiquidityToJobOfUser(_user, _liquidity, _job, 0);
  }

  function _addLiquidityOfUserToJob(
    address _user,
    address _liquidity,
    address _job,
    uint256 _amount
  ) internal {
    require(IKeep3rV1(keep3rV1).jobs(_job), 'Keep3rLiquidityManager::job-not-on-keep3r');
    require(_amount > 0, 'Keep3rLiquidityManager::zero-amount');
    require(_amount <= userLiquidityIdleAmount[_user][_liquidity], 'Keep3rLiquidityManager::no-idle-liquidity-available');
    require(liquidityMinAmount[_liquidity] != 0, 'Keep3rLiquidityManager::liquidity-min-not-set');
    require(
      userJobLiquidityLockedAmount[_user][_job][_liquidity].add(_amount) >= liquidityMinAmount[_liquidity],
      'Keep3rLiquidityManager::locked-amount-not-enough'
    );
    // set liquidity amount on user-job
    userJobLiquidityAmount[_user][_job][_liquidity] = userJobLiquidityAmount[_user][_job][_liquidity].add(_amount);
    // increase user-job liquidity locked amount
    userJobLiquidityLockedAmount[_user][_job][_liquidity] = userJobLiquidityLockedAmount[_user][_job][_liquidity].add(_amount);
    // substract amount from user idle amount
    userLiquidityIdleAmount[_user][_liquidity] = userLiquidityIdleAmount[_user][_liquidity].sub(_amount);
    // add lp to job if that lp was not being used on that job
    if (jobLiquidityDesiredAmount[_job][_liquidity] == 0) _addLPToJob(_job, _liquidity);
    // add amount to desired liquidity on job
    jobLiquidityDesiredAmount[_job][_liquidity] = jobLiquidityDesiredAmount[_job][_liquidity].add(_amount);
  }

  function _subLiquidityOfUserFromJob(
    address _user,
    address _liquidity,
    address _job,
    uint256 _amount
  ) internal {
    require(_amount <= userJobLiquidityAmount[_user][_job][_liquidity], 'Keep3rLiquidityManager::not-enough-lp-in-job');
    // only allow user job liquidity to be reduced to 0 or higher than minumum
    require(
      userJobLiquidityAmount[_user][_job][_liquidity].sub(_amount) == 0 ||
        userJobLiquidityAmount[_user][_job][_liquidity].sub(_amount) >= liquidityMinAmount[_liquidity],
      'Keep3rLiquidityManager::locked-amount-not-enough'
    );

    userJobLiquidityAmount[_user][_job][_liquidity] = userJobLiquidityAmount[_user][_job][_liquidity].sub(_amount);
    jobLiquidityDesiredAmount[_job][_liquidity] = jobLiquidityDesiredAmount[_job][_liquidity].sub(_amount);
  }

  function _removeIdleLiquidityOfUserFromJob(
    address _user,
    address _liquidity,
    address _job,
    uint256 _amount
  ) internal {
    require(_amount > 0, 'Keep3rLiquidityManager::zero-amount');
    require(
      jobCycle[_job] >= userJobCycle[_user][_job].add(2) || // wait for full cycle
        _jobLiquidities[_job].length() == 0, // or removes if 1 cycle was enough to remove all liquidity
      'Keep3rLiquidityManager::liquidity-still-locked'
    );

    _amount = _amount.div(2).mul(2);

    uint256 _unlockedIdleAvailable = userJobLiquidityLockedAmount[_user][_job][_liquidity].sub(userJobLiquidityAmount[_user][_job][_liquidity]);
    require(_amount <= _unlockedIdleAvailable, 'Keep3rLiquidityManager::amount-bigger-than-idle-available');

    userJobLiquidityLockedAmount[_user][_job][_liquidity] = userJobLiquidityLockedAmount[_user][_job][_liquidity].sub(_amount);
    userLiquidityIdleAmount[_user][_liquidity] = userLiquidityIdleAmount[_user][_liquidity].add(_amount);

    emit IdleLiquidityRemovedFromJob(_user, _liquidity, _job, _amount);
  }
}